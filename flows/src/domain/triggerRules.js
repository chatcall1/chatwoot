export const normalizeTriggerData = data => ({
  ...data,
  capture: 'first_word',
  noMatchFrequency: data.noMatchFrequency || 'always',
});
