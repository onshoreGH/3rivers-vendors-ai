"""Polish the 3Rivers demo data for App Store screenshots:
  - rewrite the two old smoke-test rows into realistic ones
  - give suppliers/vendors real names + a few more entries
Idempotent-ish: safe to re-run (upserts by id / skips if names already real)."""
import sys, uuid
from datetime import datetime, timezone, timedelta

sys.path.insert(0, "/opt/3rivers/app")
from bisera_client import get_client

B = get_client()


def iso(days=0):
    return (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()


def d(days):
    return (datetime.now(timezone.utc) + timedelta(days=days)).strftime("%Y-%m-%d")


# --- 1. fix the smoke-test work order / shipment -----------------------------
wo = B.get_by_field("work_orders", "wo_number", "WO-TEST-1")
if wo:
    wo.update(dict(
        wo_number="WO-1031", product_sku="ST-FLNG-300", product_name="Steel pipe flange",
        quantity=300, due_date=d(-4), priority="High", status="Released",
        notes="Overdue - waiting on raw stock from supplier.",
    ))
    B.insert("work_orders", wo["id"], wo)
    print("  fixed WO-TEST-1 -> WO-1031")

sh = B.get_by_field("shipments", "shipment_number", "SHP-TEST-1")
if sh:
    sh.update(dict(
        shipment_number="SHP-2187", work_order_number="WO-1031", carrier="Old Dominion",
        mode="Ground", tracking_number="OD-40221765", origin="Cleveland, OH",
        destination="Detroit, MI", ship_date=d(-5), eta_date=d(-2), status="InTransit",
        pieces=4, weight_lbs=910.0, notes="Running behind - carrier delay.",
    ))
    B.insert("shipments", sh["id"], sh)
    print("  fixed SHP-TEST-1 -> SHP-2187")

# --- 2. suppliers -----------------------------------------------------------
def upsert(collection, name, email):
    existing = B.get_by_fk(collection, "name", name)
    rec = existing or {"id": str(uuid.uuid4()), "created_at": iso(-30)}
    rec.update({"name": name, "email": email})
    B.insert(collection, rec["id"], rec)
    return "kept" if existing else "added"

acme = B.get_by_field("suppliers", "name", "Acme Supply")
if acme:
    acme.update({"name": "Midwest Metals Co.", "email": "orders@midwestmetals.example"})
    B.insert("suppliers", acme["id"], acme)
    print("  renamed Acme Supply -> Midwest Metals Co.")

for nm, em in [
    ("Great Lakes Fabrication", "sales@glfab.example"),
    ("Precision Polymers LLC", "service@precisionpolymers.example"),
    ("Detroit Casting Works", "ap@detroitcasting.example"),
]:
    print("  supplier %-26s %s" % (nm, upsert("suppliers", nm, em)))

vco = B.get_by_field("vendors", "name", "Vendor Co")
if vco:
    vco.update({"name": "Nationwide Logistics", "email": "dispatch@nationwidelog.example"})
    B.insert("vendors", vco["id"], vco)
    print("  renamed Vendor Co -> Nationwide Logistics")

for nm, em in [
    ("Old Dominion Freight", "claims@odfl.example"),
    ("Falcon Customs Brokerage", "clearance@falconcustoms.example"),
]:
    print("  vendor   %-26s %s" % (nm, upsert("vendors", nm, em)))

print("done")
