# AcrimSAT

Original NASA model, preserving embedded textures and materials.
Source: https://science.nasa.gov/3d-resources/active-cavity-irradiance-monitor-satellite-acrimsat-a/
Credit: NASA/Brian E. Kumanchik; NASA/Christian A. Lopez.

Used intact for the starter configuration. Other component combinations still use the modular kit; they are not reconstructions of AcrimSAT. The preview Earth is a textured 3D sphere using the project's existing earth-albedo-v1.png. A separate NASA Earth imagery download failed, so no new Earth imagery provenance is claimed.

## Additional selectable spacecraft

- MiRaTa: https://science.nasa.gov/3d-resources/cubesat-mirata/
- ICECube: https://science.nasa.gov/3d-resources/cubesat-icecube/

Both credited to NASA/Christopher R. Meaney. Draco mesh data was decompressed for Godot; embedded images, materials and authored transforms were preserved. Display normalization centers each complete model and fits its largest extent to three scene units; this is not a physical size comparison.

The draft's `satellite_id` is `acrimsat`, `mirata`, `icecube`, or `kit`. It is included in the validation result and immutable run snapshot. The whole-spacecraft selector is independent of modular component IDs; kit editing explicitly switches to `kit`. Production engineering specifications for these spacecraft remain unavailable.
