"""Mobile API for the 3Rivers staff iOS app.

Mounted at `/api/v1` (nginx proxies `/api/v1/` straight to :9000 with NO
`auth_request` -- this router does its own Keycloak JWT
check, it is not behind oauth2-proxy like the browser `/api/` routes).

Auth model: Resource Owner Password Credentials against Keycloak realm
`onshoretech`, public client `3rivers-mobile` (Direct Access Grants
enabled). The app sends the Keycloak access token as
`Authorization: Bearer <token>`; every route verifies it (signature,
issuer, azp, expiry) and then reuses the existing BiseraDB-backed
business logic in main.py -- read-only for v1.
"""
from __future__ import annotations

import os
from typing import Any, Dict, List, Optional

import httpx
import jwt
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jwt import PyJWKClient
from pydantic import BaseModel

import main as portal  # the existing 3Rivers API module (same process)

# Full external prefix -- the portal's routes are all defined with their own
# `/api/...` prefix (no nginx path rewrite), and nginx forwards the whole URI.
router = APIRouter(prefix="/api/v1", tags=["mobile-v1"])

KEYCLOAK_ISSUER = os.getenv(
    "KEYCLOAK_ISSUER", "https://auth.onshoresystems.ai/realms/onshoretech"
)
MOBILE_CLIENT_ID = os.getenv("KEYCLOAK_MOBILE_CLIENT_ID", "3rivers-mobile")
_TOKEN_URL = f"{KEYCLOAK_ISSUER}/protocol/openid-connect/token"

_jwks: Optional[PyJWKClient] = None


def _jwks_client() -> PyJWKClient:
    global _jwks
    if _jwks is None:
        _jwks = PyJWKClient(f"{KEYCLOAK_ISSUER}/protocol/openid-connect/certs")
    return _jwks


_bearer = HTTPBearer(auto_error=True)


def _verify(token: str) -> Dict[str, Any]:
    try:
        key = _jwks_client().get_signing_key_from_jwt(token).key
        payload = jwt.decode(
            token,
            key,
            algorithms=["RS256"],
            issuer=KEYCLOAK_ISSUER,
            options={"verify_aud": False},
        )
    except Exception:
        raise HTTPException(status_code=401, detail={"code": "invalid_token", "message": "Session expired. Sign in again."})
    if payload.get("azp") != MOBILE_CLIENT_ID:
        raise HTTPException(status_code=401, detail={"code": "wrong_client", "message": "Not authenticated."})
    realm = payload.get("realm_access") or {}
    return {
        "sub": payload.get("sub"),
        "email": payload.get("email"),
        "name": payload.get("name") or payload.get("preferred_username"),
        "preferred_username": payload.get("preferred_username"),
        "roles": realm.get("roles", []),
    }


def current_user(creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> Dict[str, Any]:
    return _verify(creds.credentials)


# --------------------------------------------------------------------------
# auth
# --------------------------------------------------------------------------
class LoginIn(BaseModel):
    username: str
    password: str


class RefreshIn(BaseModel):
    refresh_token: str


def _token_request(form: Dict[str, str]) -> Dict[str, Any]:
    form = {"client_id": MOBILE_CLIENT_ID, "scope": "openid profile email", **form}
    try:
        r = httpx.post(_TOKEN_URL, data=form, timeout=20.0)
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail={"code": "auth_unreachable", "message": "Can't reach the sign-in service."})
    if r.status_code == 401 or r.status_code == 400:
        raise HTTPException(status_code=401, detail={"code": "bad_credentials", "message": "Incorrect username or password."})
    if r.status_code >= 500:
        raise HTTPException(status_code=502, detail={"code": "auth_error", "message": "Sign-in service error. Try again."})
    r.raise_for_status()
    tok = r.json()
    return {
        "access_token": tok["access_token"],
        "refresh_token": tok.get("refresh_token"),
        "expires_in": tok.get("expires_in", 300),
        "token_type": "Bearer",
    }


@router.post("/auth/login")
def login(body: LoginIn):
    tokens = _token_request(
        {"grant_type": "password", "username": body.username, "password": body.password}
    )
    user = _verify(tokens["access_token"])
    return {**tokens, "user": user}


@router.post("/auth/refresh")
def refresh(body: RefreshIn):
    tokens = _token_request(
        {"grant_type": "refresh_token", "refresh_token": body.refresh_token}
    )
    return tokens


@router.get("/me")
def me(user: Dict[str, Any] = Depends(current_user)):
    return user


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
def _b():
    return portal.BISERA


def _sort_desc(items: List[dict], key: str = "created_at") -> List[dict]:
    return sorted(items, key=lambda x: x.get(key) or "", reverse=True)


def _live(items: List[dict]) -> List[dict]:
    return [x for x in items if not x.get("_deleted") and not x.get("_scratch")]


def _live_count(collection: str) -> int:
    return len(_live(_b().query_all(collection)))


# --------------------------------------------------------------------------
# dashboard
# --------------------------------------------------------------------------
@router.get("/dashboard")
def dashboard(user: Dict[str, Any] = Depends(current_user)):
    summary = portal.report_summary()
    wo = summary["work_orders"]
    sh = summary["shipments"]
    return {
        "generated_at": summary["generated_at"],
        "counts": {
            "suppliers": _live_count("suppliers"),
            "vendors": _live_count("vendors"),
            "work_orders": wo["total"],
            "shipments": sh["total"],
            "work_orders_overdue": wo["overdue_count"],
            "shipments_overdue": sh["overdue_count"],
        },
        "work_orders_by_status": wo["by_status"],
        "shipments_by_status": sh["by_status"],
        "overdue_work_orders": wo["overdue_sample"][:10],
        "overdue_shipments": sh["overdue_sample"][:10],
    }


# --------------------------------------------------------------------------
# work orders
# --------------------------------------------------------------------------
@router.get("/work-orders")
def work_orders(status: Optional[str] = None, user: Dict[str, Any] = Depends(current_user)):
    items = _b().query_all("work_orders")
    if status:
        items = [w for w in items if (w.get("status") or "").lower() == status.lower()]
    return {"items": _sort_desc(items)[:1000]}


@router.get("/work-orders/{wo_id}")
def work_order(wo_id: str, user: Dict[str, Any] = Depends(current_user)):
    wo = _b().get_by_field("work_orders", "id", wo_id)
    if not wo:
        raise HTTPException(status_code=404, detail={"code": "not_found", "message": "Work order not found."})
    shipments = [s for s in _b().query_all("shipments")
                 if str(s.get("work_order_number") or "") == str(wo.get("wo_number") or "")]
    return {"work_order": wo, "shipments": _sort_desc(shipments)}


# --------------------------------------------------------------------------
# shipments
# --------------------------------------------------------------------------
@router.get("/shipments")
def shipments(status: Optional[str] = None, user: Dict[str, Any] = Depends(current_user)):
    items = _b().query_all("shipments")
    if status:
        items = [s for s in items if (s.get("status") or "").lower() == status.lower()]
    return {"items": _sort_desc(items)[:1000]}


@router.get("/shipments/{sh_id}")
def shipment(sh_id: str, user: Dict[str, Any] = Depends(current_user)):
    sh = _b().get_by_field("shipments", "id", sh_id)
    if not sh:
        raise HTTPException(status_code=404, detail={"code": "not_found", "message": "Shipment not found."})
    wo = None
    if sh.get("work_order_number"):
        wo = _b().get_by_fk("work_orders", "wo_number", sh["work_order_number"])
    return {"shipment": sh, "work_order": wo}


# --------------------------------------------------------------------------
# directory (suppliers + vendors)
# --------------------------------------------------------------------------
@router.get("/directory")
def directory(kind: Optional[str] = None, user: Dict[str, Any] = Depends(current_user)):
    out: List[dict] = []
    wanted = {"supplier": "suppliers", "vendor": "vendors"}
    if kind in wanted:
        wanted = {kind: wanted[kind]}
    for ctype, collection in wanted.items():
        for item in _b().query_all(collection):
            if item.get("_deleted") or item.get("_scratch"):
                continue
            out.append({**item, "contact_type": ctype})
    out.sort(key=lambda x: (x.get("name") or "").lower())
    return {"items": out}


@router.get("/directory/{contact_type}/{contact_id}")
def directory_entry(contact_type: str, contact_id: str, user: Dict[str, Any] = Depends(current_user)):
    collection = {"supplier": "suppliers", "vendor": "vendors"}.get(contact_type)
    if not collection:
        raise HTTPException(status_code=400, detail={"code": "bad_type", "message": "Unknown contact type."})
    contact = _b().get_by_field(collection, "id", contact_id)
    if not contact:
        raise HTTPException(status_code=404, detail={"code": "not_found", "message": "Contact not found."})
    sessions = [s for s in _b().query_all("sessions")
                if s.get("contact_id") == contact_id and s.get("contact_type") == contact_type]
    return {"contact": {**contact, "contact_type": contact_type}, "sessions": _sort_desc(sessions)}


# --------------------------------------------------------------------------
# comms inbox (read-only)
# --------------------------------------------------------------------------
@router.get("/inbox")
def inbox(user: Dict[str, Any] = Depends(current_user)):
    items = _sort_desc(_b().query_all("inbox"))[:200]
    return {"items": items}


# --------------------------------------------------------------------------
# video check-in: mint a host join token for a supplier/vendor session
# --------------------------------------------------------------------------
@router.post("/directory/{contact_type}/{contact_id}/check-in")
def start_check_in(contact_type: str, contact_id: str, user: Dict[str, Any] = Depends(current_user)):
    collection = {"supplier": "suppliers", "vendor": "vendors"}.get(contact_type)
    if not collection:
        raise HTTPException(status_code=400, detail={"code": "bad_type", "message": "Unknown contact type."})
    contact = _b().get_by_field(collection, "id", contact_id)
    if not contact:
        raise HTTPException(status_code=404, detail={"code": "not_found", "message": "Contact not found."})

    import json as _json
    import secrets as _secrets
    import uuid as _uuid

    session = {
        "id": str(_uuid.uuid4()),
        "contact_type": contact_type,
        "contact_id": contact_id,
        "initiated_by": user.get("email") or user.get("preferred_username") or "unknown",
        "status": "pending",
        "started_at": None,
        "ended_at": None,
        "created_at": portal.now_iso(),
    }
    _b().insert("sessions", session["id"], session)

    host_token = _secrets.token_urlsafe(32)
    portal.REDIS.setex(
        f"3rivers:join-token:{host_token}",
        portal.HOST_TOKEN_TTL_SECONDS,
        _json.dumps({"session_id": session["id"], "role": "host", "identity": session["initiated_by"]}),
    )
    guest_token = _secrets.token_urlsafe(32)
    portal.REDIS.setex(
        f"3rivers:join-token:{guest_token}",
        portal.GUEST_TOKEN_TTL_SECONDS,
        _json.dumps({"session_id": session["id"], "role": "guest", "identity": f"{contact_type}:{contact_id}"}),
    )

    base = os.getenv("PUBLIC_PORTAL_URL", "https://3rivers.onshoretech.ai")
    return {
        "session_id": session["id"],
        "room": f"3rivers-session-{session['id']}",
        "host_url": f"{base}/sessions/join?token={host_token}",
        "host_expires_in": portal.HOST_TOKEN_TTL_SECONDS,
        "guest_url": f"{base}/sessions/join?token={guest_token}",
        "guest_expires_in": portal.GUEST_TOKEN_TTL_SECONDS,
        "contact": {**contact, "contact_type": contact_type},
    }
