# Agent-Based Model to Study the Impact of Hate Speech on Their Behaviour

This project presents an agent-based model (ABM) built using NetLogo to simulate and analyze how exposure to hate speech affects individual and group behavior over time.

## 🧠 Overview

Hate speech, both online and offline, has become a pressing social issue due to its potential to incite violence, foster division, and alter behavioral norms. This model simulates agents (individuals) interacting in a shared environment where some agents are exposed to hate speech and others are not.

The goal is to:

* Understand how hate speech spreads within a population.
* Observe behavioral changes in agents (e.g., increased aggression or social withdrawal).
* Identify thresholds where hate speech significantly alters group cohesion or leads to clustering of like-minded individuals.

## ⚙️ Platform

* **NetLogo** version 6.3.0
* Language: NetLogo (agent-based modeling environment)
* Model type: Spiral of silence model

## 🔁 Model Dynamics

### Agents (Turtles)

* Represent individuals in a population.
* Have attributes like tolerance level, aggression, susceptibility to hate speech, and social connectivity.

### Environment (Patches)

* Simulates a virtual space where agents interact.
* May contain areas representing social hotspots (e.g., online forums, neighborhoods).

### Parameters

* **Hate Speech Probability**: Likelihood of an agent spreading hate speech.
* **Tolerance Threshold**: Minimum tolerance before an agent adopts aggressive behavior.
* **Exposure Radius**: Spatial or social distance within which agents are influenced.
* **Recovery or Resistance Rate**: Ability of agents to return to normal behavior.

### Rules

* Agents interact with neighbors at each tick (time step).
* Exposure to hate speech can decrease tolerance and increase aggression.
* Clusters of like-minded or similarly affected individuals may emerge over time.

## 📊 Outputs

The model produces both visual and quantitative outputs:

* **Real-time visualization** of agent behavior (e.g., color-coded by aggression level).
* **Graphs and metrics** for:

  * Number of aggressive vs. tolerant agents over time
  * Degree of clustering or polarization
  * Average tolerance and aggression levels

## 🎯 Use Cases

* Academic research in sociology and psychology
* Policy simulation and testing intervention strategies
* Educational tool to demonstrate social contagion and polarization


## 🧪 Experiments to Try

* Vary the hate speech probability to see tipping points.
* Observe how initial population diversity affects outcomes.
* Introduce intervention agents (moderators, educators) and test impact.

## 📝 Notes

* The model is a simplification of complex human behavior and is intended for exploratory purposes.
* Results should be interpreted cautiously and complemented with empirical data when used in decision-making contexts.


## 📚 Data Sources

* \[1] Emmer, M., Leißner, L., Porten-Cheé, P., & Schaetz, N. (2021). Weizenbaum Report 2021: Politische Partizipation in Deutschland. 
* \[2] Palekar, S., Atapattu, M. R., Sedera, D., & Lokuge, S. (2018). Exploring spiral of silence in digital social networking spaces. In International Conference on Information Systems (ICIS 2015): Exploring the Information Frontier. Association for Information Systems (AIS).
* \[3] Schaetz, N., Leißner, L., Porten-Cheé, P., Emmer, M., & Strippel, C. (2020). Politische Partizipation in Deutschland 2019.
* \[4] Thomas, K., Akhawe, D., Bailey, M., Boneh, D., Bursztein, E., Consolvo, S., Dell, N., Durumeric, Z., Kelley, P. G., Kumar, D., McCoy, D., Meiklejohn, S., Ristenpart, T., & Stringhini, G. (2021). SoK: Hate, harassment, and the changing landscape of online abuse. 2021 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40001.2021.00028  



