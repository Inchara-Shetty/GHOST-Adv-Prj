🧠 GHOST — LLM-Generated Hardware Trojan Simulation

Lab Assignment 06
Authors: Janani Palani (jp7510), Inchara Vittal Shetty (ivs2027)

📘 Overview

This project demonstrates the GHOST framework — an LLM-powered pipeline for generating, simulating, and detecting hardware Trojans in Verilog circuits.
The workflow automates loading clean RTL designs, constructing Trojan insertion prompts, parsing model responses, and validating functionality through simulation.

⚙️ Steps Implemented

Initialize OpenAI environment and import dependencies

Load base Verilog designs (e.g., half_adder, full_adder)

Construct Trojan insertion prompt templates

Run model inference and extract Verilog + metadata

Save vulnerable RTL designs and testbenches

Compile and simulate using Icarus Verilog (iverilog + vvp) to detect Trojans

🧩 Trojan Types & Behavior
|  ID | Vulnerability Type      | Effect                                 | Trigger Condition         |
| :-: | :---------------------- | :------------------------------------- | :------------------------ |
|  T1 | Functionality Change    | Inverts sum output under rare inputs   | ( a,b,cin ) = (1,1,0) × 8 |
|  T2 | Information Leakage     | Leaks internal carry via covert output | ( a,b,cin ) = (1,0,1) × 8 |
|  T3 | Denial of Service       | Forces outputs to zero                 | ( a,b,cin ) = (1,0,1) × 3 |
|  T4 | Performance Degradation | Activates shift register → high power  | ( a,b,cin ) = (1,1,1) × 6 |


🧪 Testing & Validation

Each Trojan variant includes a dedicated Verilog testbench verifying:

Baseline functional behavior (pre-trigger)

Trigger activation sequence

Post-trigger response and VCD waveform inspection

🛠️ Troubleshooting & Design Decisions

Cleaned model outputs to remove markdown/comments

Repaired syntax errors post-generation via iverilog checks

Tuned trigger cycles (6–8) for reliable activation

Verified baseline operation before Trojan trigger
