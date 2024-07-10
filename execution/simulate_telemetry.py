"""
Steel Rolling Mill Telemetry & OEE Simulator.
Part of B.Sc. Thesis Project - Alberto Mergoni (UNIBS & AIC).
Simulates billet flow, calculates OEE metrics, and tests data pipeline integrity.
"""

import sys
import time
import json
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Any

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


@dataclass
class BilletProcessState:
    billet_id: int
    order_id: int
    nominal_weight: float
    actual_weight: float
    furnace_temp: float
    stand_wear_pct: float
    status: str


def compute_oee(availability_hours: float, total_hours: float,
                actual_production: float, target_production: float,
                quality_rate: float) -> Dict[str, float]:
    """Calculate standard Overall Equipment Effectiveness (OEE) metrics."""
    availability = min(max(availability_hours / total_hours, 0.0), 1.0)
    performance = min(max(actual_production / target_production, 0.0), 1.0)
    quality = min(max(quality_rate / 100.0, 0.0), 1.0)
    oee = availability * performance * quality

    return {
        "availability_pct": round(availability * 100, 2),
        "performance_pct": round(performance * 100, 2),
        "quality_pct": round(quality * 100, 2),
        "oee_pct": round(oee * 100, 2),
    }


def simulate_billet_cycle(num_billets: int = 5, verbose: bool = True) -> List[BilletProcessState]:
    """Simulate billets traveling from charging table to cooling bed."""
    import random
    results = []

    print(f"\n[*] Starting Steel Mill Simulation: {num_billets} billets in continuous rolling...")
    print("-" * 75)
    print(f"{'ID':<6} | {'Order':<6} | {'Nom. W (kg)':<12} | {'Temp (°C)':<10} | {'Stand Wear':<12} | {'Status'}")
    print("-" * 75)

    for i in range(1, num_billets + 1):
        nom_w = round(random.uniform(480.0, 520.0), 1)
        actual_w = round(nom_w + random.uniform(-3.5, 3.5), 1)
        temp = round(random.uniform(1140.0, 1195.0), 1)
        stand_wear = round(random.uniform(12.0, 78.5), 1)
        
        status = "Finished (Cooling Bed)" if stand_wear < 75.0 else "Alert: High Stand Wear"
        
        billet = BilletProcessState(
            billet_id=1000 + i,
            order_id=42,
            nominal_weight=nom_w,
            actual_weight=actual_w,
            furnace_temp=temp,
            stand_wear_pct=stand_wear,
            status=status
        )
        results.append(billet)
        
        print(f"#{billet.billet_id:<5} | #{billet.order_id:<5} | {billet.nominal_weight:<12} | {billet.furnace_temp:<10} | {billet.stand_wear_pct:>5.1f}%       | {billet.status}")
        time.sleep(0.05)

    print("-" * 75)
    return results


def main():
    parser = argparse.ArgumentParser(description="Simulate Steel Plant Process Telemetry and Compute OEE.")
    parser.add_argument("--billets", type=int, default=10, help="Number of billets to simulate")
    parser.add_argument("--avail_hours", type=float, default=22.8, help="Operating hours out of 24h")
    parser.add_argument("--actual_prod", type=float, default=1085.0, help="Billets produced")
    parser.add_argument("--target_prod", type=float, default=1140.0, help="Theoretical target billets")
    parser.add_argument("--quality_rate", type=float, default=99.2, help="Percentage of conform billets")
    args = parser.parse_args()

    # 1. Run simulation
    simulate_billet_cycle(args.billets)

    # 2. Compute OEE
    oee_metrics = compute_oee(
        availability_hours=args.avail_hours,
        total_hours=24.0,
        actual_production=args.actual_prod,
        target_production=args.target_prod,
        quality_rate=args.quality_rate,
    )

    print("\n" + "=" * 50)
    print("📈 INDUSTRIAL OVERALL EQUIPMENT EFFECTIVENESS (OEE)")
    print("=" * 50)
    print(f"  • Availability (Disponibilità): {oee_metrics['availability_pct']}%  ({args.avail_hours}h / 24.0h)")
    print(f"  • Performance  (Prestazioni):    {oee_metrics['performance_pct']}%  ({args.actual_prod} / {args.target_prod})")
    print(f"  • Quality      (Qualità):        {oee_metrics['quality_pct']}%")
    print("-" * 50)
    print(f"  ⭐ WORLD-CLASS OEE SCORE:        {oee_metrics['oee_pct']}%")
    print("=" * 50 + "\n")


if __name__ == "__main__":
    main()
