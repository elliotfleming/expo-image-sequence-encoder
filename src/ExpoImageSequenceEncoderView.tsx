import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoImageSequenceEncoderViewProps } from './ExpoImageSequenceEncoder.types';

const NativeView: React.ComponentType<ExpoImageSequenceEncoderViewProps> =
  requireNativeView('ExpoImageSequenceEncoder');

export default function ExpoImageSequenceEncoderView(props: ExpoImageSequenceEncoderViewProps) {
  return <NativeView {...props} />;
}
