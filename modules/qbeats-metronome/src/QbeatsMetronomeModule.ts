import { NativeModule, requireNativeModule } from 'expo';

import { QbeatsMetronomeModuleEvents } from './QbeatsMetronome.types';

declare class QbeatsMetronomeModule extends NativeModule<QbeatsMetronomeModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<QbeatsMetronomeModule>('QbeatsMetronome');
