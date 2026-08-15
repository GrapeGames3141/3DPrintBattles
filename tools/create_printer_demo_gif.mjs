#!/usr/bin/env node
/*
 * Builds the looping PrintForge printer showcase with Sharp.
 *
 * Run this module with the persistent Node renderer that provides Sharp:
 *   PRINTFORGE_SOURCE_ROOT="E:\\AI Projects\\games\\3d print battler"
 *   import("./tools/create_printer_demo_gif.mjs")
 *
 * Optional environment variables:
 *   PRINTFORGE_SOURCE_ROOT - project containing the source PNG art
 *   PRINTFORGE_DEMO_GIF    - destination GIF path
 */
import sharp from 'sharp';
import { mkdir, stat } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const stagedProjectRoot = resolve(scriptDirectory, '..');
const configuredEnv = globalThis.process?.env || {};
const outputGif = resolve(globalThis.PRINTFORGE_DEMO_GIF || configuredEnv.PRINTFORGE_DEMO_GIF || join(stagedProjectRoot, 'docs', 'demo', 'printforge_cinderpaw_printing.gif'));
const sourceRoot = resolve(globalThis.PRINTFORGE_SOURCE_ROOT || configuredEnv.PRINTFORGE_SOURCE_ROOT || stagedProjectRoot);
const outputPoster = outputGif.replace(/\.gif$/i, '_poster.png');
const outputContactSheet = outputGif.replace(/\.gif$/i, '_contact_sheet.png');
const size = 672;
const frameRate = 10;
const frameCount = 48;
const frameDelay = 100;
const printerOrder = [1, 2, 3, 4, 3, 2];
const printerRoot = join(sourceRoot, 'assets', 'ui');
const creaturePath = join(sourceRoot, 'assets', 'creatures', '2d', 'raw', 'cinderpaw_raw_print.png');

const printerPath = (index) => join(printerRoot, `arcane_forge_printer_frame_${String(index).padStart(2, '0')}.png`);
const revealAmount = (frame) => Math.max(2, Math.min(252, Math.floor(252 * Math.max(0, Math.min(1, ((frame / frameRate) - 0.25) / 2.6)))));

const backgroundSvg = Buffer.from(`
  <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="halo" cx="50%" cy="47%" r="64%">
        <stop offset="0%" stop-color="#10294a"/>
        <stop offset="48%" stop-color="#071425"/>
        <stop offset="100%" stop-color="#030711"/>
      </radialGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#halo)"/>
  </svg>
`);

function scanLineSvg(reveal) {
  const y = 418 - reveal;
  return Buffer.from(`
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
      <rect x="208" y="${y}" width="255" height="14" rx="7" fill="#00e5ff" opacity="0.14"/>
      <rect x="210" y="${y + 6}" width="251" height="2" rx="1" fill="#a4fbff" opacity="0.98"/>
    </svg>
  `);
}

async function prepareArtwork() {
  const printerFrames = await Promise.all(printerOrder.map((index) =>
    sharp(printerPath(index)).resize(size, size, { fit: 'fill', kernel: sharp.kernel.lanczos3 }).png().toBuffer(),
  ));
  const creature = await sharp(creaturePath).resize(252, 252, { fit: 'fill', kernel: sharp.kernel.lanczos3 }).png().toBuffer();
  const background = await sharp(backgroundSvg).png().toBuffer();
  return { background, creature, printerFrames };
}

async function composeFrame(artwork, frame, includeScan = true) {
  const reveal = revealAmount(frame);
  const creatureSlice = await sharp(artwork.creature)
    .extract({ left: 0, top: 252 - reveal, width: 252, height: reveal })
    .png()
    .toBuffer();
  const layers = [
    { input: artwork.printerFrames[frame % artwork.printerFrames.length], left: 0, top: 0 },
    { input: creatureSlice, left: 210, top: 183 + (252 - reveal) },
  ];
  if (includeScan && frame / frameRate >= 0.25 && frame / frameRate <= 3.1) layers.push({ input: scanLineSvg(reveal), left: 0, top: 0 });
  return sharp(artwork.background).composite(layers).png().toBuffer();
}

export async function createPrinterDemo() {
  await mkdir(dirname(outputGif), { recursive: true });
  const artwork = await prepareArtwork();
  const frames = await Promise.all(Array.from({ length: frameCount }, (_, frame) => composeFrame(artwork, frame)));
  await sharp(frames, { join: { animated: true } })
    .gif({ loop: 0, delay: Array(frameCount).fill(frameDelay), effort: 8, colours: 256, dither: 0.7 })
    .toFile(outputGif);

  const poster = await composeFrame(artwork, frameCount - 1, false);
  await sharp(poster).png().toFile(outputPoster);

  const contactIndexes = [0, 8, 16, 24, 32, 47];
  const contactLayers = contactIndexes.map((index, position) => ({
    input: frames[index],
    left: (position % 3) * size,
    top: Math.floor(position / 3) * size,
  }));
  await sharp({ create: { width: size * 3, height: size * 2, channels: 4, background: '#030711' } })
    .composite(contactLayers)
    .png()
    .toFile(outputContactSheet);

  const [gifInfo, posterInfo, contactInfo] = await Promise.all([stat(outputGif), stat(outputPoster), stat(outputContactSheet)]);
  console.log(JSON.stringify({
    outputGif, bytes: gifInfo.size, dimensions: `${size}x${size}`, frames: frameCount, frameRate, loop: 'infinite',
    outputPoster, posterBytes: posterInfo.size, outputContactSheet, contactBytes: contactInfo.size,
  }, null, 2));
}

await createPrinterDemo();
