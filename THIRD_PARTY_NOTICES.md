# Third-party notices

Status: first version, 2026-11-28. It lists only what is verified. Not a finished release notice.

AK Engine itself is GPL-3.0-only (see `LICENSE`).

## Code copied into this repository from other projects

None at the moment. The `godot_module` and `project/addons/ak_modeler` code is written for AK Engine. The `upstream/` folder holds only a README (no upstream source is committed).

If code is copied or ported later, add a row here with: origin project, origin file, origin commit or tag, licence, SPDX header kept (yes or no), and whether it is editor-only. Blender-derived code is editor-only and never goes into runtime modules or export templates.

## Used at build or test time, not redistributed here

| Project | Version | Licence | How it is used |
|---|---|---|---|
| Godot Engine | 4.7.2-stable | MIT (its `thirdparty/` parts have their own licences, listed in its `COPYRIGHT.txt`) | Built in CI as the runtime and export base. Any release that ships a Godot build must ship its `COPYRIGHT.txt`. |
| O3DE | 2610.0 | Apache-2.0 or MIT; its Qt use is LGPL-3.0 and is not used here | Built in CI for the render probe only. Nothing from O3DE is committed. |

## Assets

See `docs/THIRD_PARTY_ASSETS.md`. The CC0 car (tevy.dev) is EXPERIMENTAL: the publisher claims CC0 and authorship is unverified. Do not ship it in a release until that is checked.

## Not yet audited

Dependency trees of O3DE (3p packages) and Blender (lib repo, for example OpenSubdiv, OpenVDB, Embree).
