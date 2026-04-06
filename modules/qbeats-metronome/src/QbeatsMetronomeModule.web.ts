import { registerWebModule, NativeModule } from 'expo';

import { ChangeEventPayload } from './QbeatsMetronome.types';

type QbeatsMetronomeModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
}

class QbeatsMetronomeModule extends NativeModule<QbeatsMetronomeModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
};

export default registerWebModule(QbeatsMetronomeModule, 'QbeatsMetronomeModule');
