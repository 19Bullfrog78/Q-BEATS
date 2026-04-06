import { requireNativeView } from 'expo';
import * as React from 'react';

import { QbeatsMetronomeViewProps } from './QbeatsMetronome.types';

const NativeView: React.ComponentType<QbeatsMetronomeViewProps> =
  requireNativeView('QbeatsMetronome');

export default function QbeatsMetronomeView(props: QbeatsMetronomeViewProps) {
  return <NativeView {...props} />;
}
