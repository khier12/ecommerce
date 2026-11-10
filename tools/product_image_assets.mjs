import {posix} from 'node:path';

// Website exports can still name the original PNG after the app uses WebP.
export function resolveProductImage(filename, availableFiles) {
  const original = posix.basename(filename);
  const optimized = original.replace(/\.[^.]+$/, '.webp');
  if (availableFiles.has(optimized)) return `assets/images/${optimized}`;
  if (availableFiles.has(original)) return `assets/images/${original}`;
  throw Error(`Missing product image or filename case mismatch: ${original}`);
}

export function imageDimensions(bytes) {
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    return {format: 'png', width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20), alpha: [4, 6].includes(bytes[25])};
  }
  if (bytes.toString('ascii', 0, 4) !== 'RIFF' || bytes.toString('ascii', 8, 12) !== 'WEBP') return null;
  for (let offset = 12; offset + 8 <= bytes.length;) {
    const type = bytes.toString('ascii', offset, offset + 4);
    const length = bytes.readUInt32LE(offset + 4), start = offset + 8;
    if (start + length > bytes.length) throw Error('Truncated WebP image.');
    if (type === 'VP8X' && length >= 10) return {format: 'webp', width: 1 + bytes.readUIntLE(start + 4, 3), height: 1 + bytes.readUIntLE(start + 7, 3), alpha: Boolean(bytes[start] & 16)};
    if (type === 'VP8 ' && length >= 10) return {format: 'webp', width: bytes.readUInt16LE(start + 6) & 0x3fff, height: bytes.readUInt16LE(start + 8) & 0x3fff, alpha: false};
    if (type === 'VP8L' && length >= 5) {
      const bits = bytes.readUInt32LE(start + 1);
      return {format: 'webp', width: (bits & 0x3fff) + 1, height: ((bits >>> 14) & 0x3fff) + 1, alpha: Boolean(bits & 0x10000000)};
    }
    offset = start + length + (length & 1);
  }
  throw Error('WebP dimensions were not found.');
}
