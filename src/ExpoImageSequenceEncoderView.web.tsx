import * as React from 'react';

import { ExpoImageSequenceEncoderViewProps } from './ExpoImageSequenceEncoder.types';

export default function ExpoImageSequenceEncoderView(props: ExpoImageSequenceEncoderViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
