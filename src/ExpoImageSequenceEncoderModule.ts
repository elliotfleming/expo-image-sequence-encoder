// src/ExpoImageSequenceEncoderModule.ts

import { NativeModule, requireNativeModule } from 'expo'

import { EncoderOptions, ExpoImageSequenceEncoderModuleEvents } from './ExpoImageSequenceEncoder.types'

declare class ExpoImageSequenceEncoderModule extends NativeModule<ExpoImageSequenceEncoderModuleEvents> {
  encode(options: EncoderOptions): Promise<string>
}

export default requireNativeModule<ExpoImageSequenceEncoderModule>('ExpoImageSequenceEncoder')
