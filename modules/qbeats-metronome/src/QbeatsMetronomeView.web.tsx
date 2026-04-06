import * as React from 'react';

import { QbeatsMetronomeViewProps } from './QbeatsMetronome.types';

export default function QbeatsMetronomeView(props: QbeatsMetronomeViewProps) {
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
