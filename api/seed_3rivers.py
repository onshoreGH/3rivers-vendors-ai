"""Seed a handful of demo work orders + shipments so the app screenshots
aren't bare. Idempotent: skips if there are already >= 4 work orders.
Run as the three_rivers user with the BiseraDB env sourced."""
import sys, uuid
from datetime import datetime, timezone, timedelta

sys.path.insert(0, "/opt/3rivers/app")
from bisera_client import get_client

B = get_client()


def iso(days=0):
    return (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()


def d(days=0):
    return (datetime.now(timezone.utc) + timedelta(days=days)).strftime("%Y-%m-%d")


existing = B.query_all("work_orders")
if len([w for w in existing if not w.get("_deleted")]) >= 4:
    print("  already seeded (%d work orders) — skipping" % len(existing))
    sys.exit(0)

WOS = [
    dict(wo_number="WO-1042", product_sku="AL-BRK-500", product_name="Aluminum mounting bracket",
         quantity=500, due_date=d(6), priority="High", status="Released", notes="Customer rush order."),
    dict(wo_number="WO-1043", product_sku="ST-HSG-200", product_name="Steel gearbox housing",
         quantity=200, due_date=d(14), priority="Normal", status="InProgress", notes=""),
    dict(wo_number="WO-1044", product_sku="PL-CVR-1200", product_name="Polymer access cover",
         quantity=1200, due_date=d(21), priority="Low", status="Planned", notes=""),
    dict(wo_number="WO-1039", product_sku="AL-BRK-500", product_name="Aluminum mounting bracket",
         quantity=250, due_date=d(-3), priority="Normal", status="Complete", notes="Shipped in full."),
]
SHIPS = [
    dict(shipment_number="SHP-2201", work_order_number="WO-1042", carrier="FedEx Freight",
         mode="Ground", tracking_number="7712 8843 1200", origin="Detroit, MI",
         destination="Chicago, IL", ship_date=d(-1), eta_date=d(2), status="InTransit",
         pieces=6, weight_lbs=1420.0, notes=""),
    dict(shipment_number="SHP-2198", work_order_number="WO-1039", carrier="UPS",
         mode="Ground", tracking_number="1Z999AA10123456784", origin="Detroit, MI",
         destination="Columbus, OH", ship_date=d(-6), eta_date=d(-4), status="Delivered",
         pieces=3, weight_lbs=680.0, notes="POD signed."),
    dict(shipment_number="SHP-2203", work_order_number="", carrier="XPO Logistics",
         mode="Ground", tracking_number="XPO-55219034", origin="Toledo, OH",
         destination="Grand Rapids, MI", ship_date=d(-2), eta_date=d(-1), status="Exception",
         pieces=2, weight_lbs=410.0, notes="Weather delay in transit."),
]

for w in WOS:
    rec = {"id": str(uuid.uuid4()), **w, "created_at": iso(-2), "created_by": "seed"}
    B.insert("work_orders", rec["id"], rec)
    print("  + work order", w["wo_number"])

for s in SHIPS:
    rec = {"id": str(uuid.uuid4()), **s, "created_at": iso(-2), "created_by": "seed"}
    B.insert("shipments", rec["id"], rec)
    print("  + shipment", s["shipment_number"])

print("  seeded %d work orders, %d shipments" % (len(WOS), len(SHIPS)))
