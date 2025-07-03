// src/ExpoImageSequenceEncoder.types.ts

export type ExpoImageSequenceEncoderModuleEvents = {}

export interface EncoderOptions {
  /** Directory containing the frame-PNGs. Must end with “/”. */
  folder: string
  /** Frames per second for the output file. */
  fps: number
  /** Output video width (pixels). */
  width: number
  /** Output video height (pixels). */
  height: number
  /** Absolute destination path for the MP4 (will be overwritten). */
  output: string
}
