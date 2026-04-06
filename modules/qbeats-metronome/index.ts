// Reexport the native module. On web, it will be resolved to QbeatsMetronomeModule.web.ts
// and on native platforms to QbeatsMetronomeModule.ts
export { default } from './src/QbeatsMetronomeModule';
export { default as QbeatsMetronomeView } from './src/QbeatsMetronomeView';
export * from  './src/QbeatsMetronome.types';
