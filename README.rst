School Van Tracking: Ordering Guarantees Under Unreliable Networks
================================================================

.. image:: https://zenodo.org/badge/DOI/10.5281/zenodo.23567441.svg
   :target: https://doi.org/10.5281/zenodo.23567441
   :alt: DOI

Formal verification artifacts and technical report for the school-van tracking
telemetry protocol (TLA+, TLC, and fault-injection tests).


Abstract
--------

We study the telemetry protocol of a real-time school-van tracking app, where a
driver's phone streams GPS positions to parents over unreliable mobile networks.
Using TLA+ and TLC, we model unordered driver-to-server and server-to-parent
channels with unbounded redelivery. TLC finds a ``MonotonicDisplay`` violation in
the baseline; **the parent display guard alone** is sufficient for monotonicity in this
model, while a server-only guard does not. Production uses both guards for server
state and ancillary consumers, not because the server guard alone protects the
map. Raw TLC logs are in ``tlc/``; see ``MODELING.md``.


Repository Contents
-------------------

* ``paper/School_Van_Tracking.pdf`` — Current technical report (v1.2.0). Start
  here.
* ``paper/School_Van_Tracking.tex`` — LaTeX source of the report. Rebuild with
  ``pdflatex School_Van_Tracking.tex`` (run twice) or on Overleaf.
* The v1.0 report (single-channel model) is archived with the v1.0.0 release:
  https://doi.org/10.5281/zenodo.23567442
* ``SchoolVanTracker_Baseline.tla`` — No guards.
* ``SchoolVanTracker_ServerGuarded.tla`` / ``SchoolVanTracker_ParentGuarded.tla``
  — Ablation (one guard each).
* ``SchoolVanTracker_Guarded.tla`` — Both guards (deployed protocol).
* ``SchoolVanTracker_PlusCal.tla`` — PlusCal sketch of the guarded protocol
  (driver, server, parent, network processes). Its processes are declared
  ``fair``, unlike the TLA+ specs above, which use no fairness; it is not
  model-checked in ``tlc/``.
* Matching ``*.cfg`` for each TLA+ module.
* ``MODELING.md`` — Assumptions and TLC ablation table.
* ``tlc/`` — Unedited TLC console logs.


Reproducibility
---------------

TLA+ Toolbox, VS Code TLA+ extension, or ``tla2tools.jar``. From the repo root:

.. code-block:: text

   java -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_Baseline.cfg SchoolVanTracker_Baseline.tla
   java -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_ServerGuarded.cfg SchoolVanTracker_ServerGuarded.tla
   java -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_ParentGuarded.cfg SchoolVanTracker_ParentGuarded.tla
   java -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_Guarded.cfg SchoolVanTracker_Guarded.tla

See ``tlc/README.md``. ``CHECK_DEADLOCK FALSE`` on all configs.


License
-------

TLA+/PlusCal specifications, TLC configurations, and TLC logs: MIT (``LICENSE``).
Paper, report, and documentation: CC BY 4.0 (``LICENSE-docs``).
Citation metadata: ``CITATION.cff`` and ``.zenodo.json``.