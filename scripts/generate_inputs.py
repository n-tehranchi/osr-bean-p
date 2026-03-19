#!/usr/bin/env python3
"""Generate OpenSimRoot input files for a bean secondary-growth × phosphorus factorial.

Creates 39 XML input files (3 phenotypes × 13 P levels) by:
  1. Reading two template XMLs (advanced and reduced secondary growth)
  2. Creating an intermediate phenotype by averaging the secondary growth rate multiplier
  3. Varying soil phosphorus concentration across 13 levels (0.17–5.0 kg/ha)

Conversion from kg P/ha to umol P/ml:
  C = P_rate × 10 / (MW_P × depth)
  where MW_P = 30.97 g/mol, depth = 20 cm (topsoil mixing depth)
"""

import os
import re
import copy
from pathlib import Path

# --- Configuration -----------------------------------------------------------

INPUTS_DIR = Path(__file__).resolve().parent.parent / "inputs"

TEMPLATE_ADVANCED = INPUTS_DIR / "SimRoot4_bean_carioca.xml"
TEMPLATE_REDUCED = INPUTS_DIR / "SimRoot4_bean_carioca_reducedSecondaryGrowth.xml"

P_LEVELS_KG_HA = [0.17, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]

# Phenotype name → secondary growth rate multiplier value
PHENOTYPES = {
    "advanced": 1.0,
    "intermediate": 0.5,
    "reduced": 0.0,
}

# Conversion constants
MW_P = 30.97        # g/mol  (molecular weight of elemental phosphorus)
TOPSOIL_DEPTH = 20  # cm     (mixing depth for P distribution)


# --- Helpers -----------------------------------------------------------------

def kg_ha_to_umol_ml(p_kg_ha: float) -> float:
    """Convert phosphorus application rate (kg/ha) to soil concentration (umol/ml).

    Assumes uniform distribution over TOPSOIL_DEPTH cm of soil.
    1 kg/ha = 1e-5 g/cm²  →  over d cm = 1e-5/d g/cm³
    g/cm³ → umol/cm³ = (1e-5/d) / MW_P × 1e6 = 10 / (MW_P × d)
    """
    return p_kg_ha * 10.0 / (MW_P * TOPSOIL_DEPTH)


def set_secondary_growth_multiplier(xml_text: str, value: float) -> str:
    """Replace all secondary growth rate multiplier values in the XML."""
    return re.sub(
        r'(<parameter\s+name="secondary growth rate multiplier">)'
        r'[^<]+'
        r'(</parameter>)',
        rf'\g<1>{value}\g<2>',
        xml_text,
    )


def set_phosphorus_concentration(xml_text: str, conc_umol_ml: float) -> str:
    """Replace the phosphorus soil-solution concentration table values.

    The template table looks like:
      <table name="concentration" ...>
        -1000 0.001  -30 0.001  ...  0 0.001
        0.0001 0  1000 0
      </table>
    inside the <phosphorus> block under <soil>.

    Strategy: find the <phosphorus> block under <soil>, then within it replace
    the concentration table's numeric values (preserving depth keys and the
    above-surface zeros).
    """
    # Match the phosphorus section inside <soil>
    soil_p_pattern = re.compile(
        r'(<soil>.*?<phosphorus>.*?'
        r'<table\s+name="concentration"[^>]*>)'
        r'(.*?)'
        r'(</table>)',
        re.DOTALL,
    )

    def replace_conc_values(match):
        prefix = match.group(1)
        table_body = match.group(2)
        suffix = match.group(3)

        # The table body has depth-value pairs.  Replace non-zero concentration
        # values (the ones at negative depths / zero depth) with the new value,
        # but keep the zero values for above-surface entries.
        # Pattern: a depth token followed by a value token
        def replace_pair(pair_match):
            depth_str = pair_match.group(1)
            val_str = pair_match.group(2)
            depth = float(depth_str)
            old_val = float(val_str)
            # Keep zeros (above-surface boundary) as-is
            if depth > 0 or old_val == 0:
                return pair_match.group(0)
            return f"{depth_str} {conc_umol_ml:.6g}"

        new_body = re.sub(
            r'(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s+'
            r'(\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)',
            replace_pair,
            table_body,
        )
        return prefix + new_body + suffix

    # Only replace the FIRST match (inside <soil>), not nutrient-uptake sections
    return soil_p_pattern.sub(replace_conc_values, xml_text, count=1)


# --- Main --------------------------------------------------------------------

def main():
    # Read templates
    advanced_xml = TEMPLATE_ADVANCED.read_text()
    reduced_xml = TEMPLATE_REDUCED.read_text()

    # Use the advanced template as the base for intermediate (it has multiplier=1;
    # we just set it to 0.5)
    base_xmls = {
        "advanced": advanced_xml,
        "intermediate": advanced_xml,  # will get multiplier overwritten to 0.5
        "reduced": reduced_xml,
    }

    filenames = []

    for phenotype, multiplier in PHENOTYPES.items():
        base = base_xmls[phenotype]
        xml_with_phenotype = set_secondary_growth_multiplier(base, multiplier)

        for p_level in P_LEVELS_KG_HA:
            conc = kg_ha_to_umol_ml(p_level)
            xml_final = set_phosphorus_concentration(xml_with_phenotype, conc)

            fname = f"bean_{phenotype}_p{p_level:.2f}.xml"
            out_path = INPUTS_DIR / fname
            out_path.write_text(xml_final)
            filenames.append(fname)
            print(f"  wrote {fname}  (P = {p_level} kg/ha → {conc:.6g} umol/ml, multiplier = {multiplier})")

    # Write Identifiers.txt
    id_path = INPUTS_DIR / "Identifiers.txt"
    id_path.write_text("\n".join(filenames) + "\n")
    print(f"\n  wrote Identifiers.txt ({len(filenames)} entries)")


if __name__ == "__main__":
    main()
