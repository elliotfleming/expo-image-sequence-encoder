import { registerWebModule, NativeModule } from 'expo';

import { ExpoImageSequenceEncoderModuleEvents } from './ExpoImageSequenceEncoder.types';

class ExpoImageSequenceEncoderModule extends NativeModule<ExpoImageSequenceEncoderModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoImageSequenceEncoderModule, 'ExpoImageSequenceEncoderModule');
