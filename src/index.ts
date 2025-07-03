// src/index.ts

// export { default } from './ExpoImageSequenceEncoderModule'
// export * from './ExpoImageSequenceEncoder.types'

import ExpoImageSequenceEncoderModule from './ExpoImageSequenceEncoderModule'
import { EncoderOptions } from './ExpoImageSequenceEncoder.types'

export function encode(options: EncoderOptions): Promise<string> {
  return ExpoImageSequenceEncoderModule.encode(options)
}
