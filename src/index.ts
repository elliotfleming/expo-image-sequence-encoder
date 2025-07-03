// Reexport the native module. On web, it will be resolved to ExpoImageSequenceEncoderModule.web.ts
// and on native platforms to ExpoImageSequenceEncoderModule.ts
export { default } from './ExpoImageSequenceEncoderModule';
export { default as ExpoImageSequenceEncoderView } from './ExpoImageSequenceEncoderView';
export * from  './ExpoImageSequenceEncoder.types';
