// Removes KTX2/basisu textures so the engine glTF importer can load the model (keeps material colours). Used only by the car-import test.
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
const doc = await io.read(process.argv[2]);
for (const t of doc.getRoot().listTextures()) t.dispose();
for (const ext of doc.getRoot().listExtensionsUsed()) if (ext.extensionName === 'KHR_texture_basisu') ext.dispose();
await io.write(process.argv[3], doc);
console.log('stripped textures');
