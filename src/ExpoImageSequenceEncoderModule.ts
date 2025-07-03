import { NativeModule, requireNativeModule } from 'expo';

import { ExpoImageSequenceEncoderModuleEvents } from './ExpoImageSequenceEncoder.types';

declare class ExpoImageSequenceEncoderModule extends NativeModule<ExpoImageSequenceEncoderModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoImageSequenceEncoderModule>('ExpoImageSequenceEncoder');
