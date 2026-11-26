# AK Engine branding

The original AK mark pairs a white A and mint K in a charcoal badge. The horizontal lockup and 16:9 splash use outlined lettering and need no font dependencies. These are supplied as opt-in files, not installed into the runtime, editor build, or sample project.

| File | Intended use |
| --- | --- |
| `ak-logo.svg` | Horizontal project lockup on a dark surface |
| `ak-icon.svg`, `ak-icon-32.png`, `ak-icon-256.png` | Scalable icon and preview rasters |
| `ak-splash.svg`, `ak-splash.png` | Editable source and 1280×720 boot artwork |
| `ak-editor-theme.tres` | Starter dark theme with accent focus ring and button states |

Palette: canvas `#101820`, surface `#182631`, border `#365162`, ink `#EAF2F4`, accent `#69E0C2`.

Preview the theme by pointing Godot's Editor Settings → Interface → Theme → Custom Theme to the `.tres` file, following [EditorSettings](https://docs.godotengine.org/en/stable/classes/class_editorsettings.html#class-editorsettings-property-interface-theme-custom-theme). This is a partial override, not a full skin; clear Custom Theme to revert. The PNG splash is artwork only; setting it in a project's **Application > Boot Splash** changes that project's boot screen, not the editor's own startup. The app icon is supplied as SVG/PNG artwork; OS packaging icons are not integrated.

SVG, raster artwork, and theme are original AK Studio contributions under the repository [MIT license](../LICENSE). No external assets or typefaces. Re-export the SVGs with Inkscape (the PNGs were rasterized from their corresponding SVGs).
