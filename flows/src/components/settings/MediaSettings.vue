<script setup>
import { computed, ref } from 'vue';
import { DirectUpload } from 'activestorage';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { setDirectUploadAuthHeaders } from 'dashboard/helper/directUploadsHelper';
import Spinner from 'shared/components/Spinner.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  data: { type: Object, required: true },
  nodeType: { type: String, required: true },
  showCaption: { type: Boolean, default: true },
});
const emit = defineEmits(['update']);
const accountId = useMapGetter('getCurrentAccountId');
const uploadState = ref('idle');

const MEDIA_RULES = {
  image: { accept: 'image/jpeg,image/png', maxBytes: 5 * 1024 * 1024 },
  video: { accept: 'video/mp4,video/3gpp', maxBytes: 16 * 1024 * 1024 },
  document: {
    accept:
      '.txt,.xls,.xlsx,.doc,.docx,.ppt,.pptx,.pdf,application/pdf,text/plain',
    maxBytes: 100 * 1024 * 1024,
  },
  audio: {
    accept: 'audio/aac,audio/amr,audio/mpeg,audio/mp4,audio/ogg',
    maxBytes: 16 * 1024 * 1024,
  },
  sticker: { accept: 'image/webp,.webp', maxBytes: 500 * 1024 },
};

const rule = computed(() => MEDIA_RULES[props.nodeType]);
const maxSizeLabel = computed(() => `${rule.value.maxBytes / 1024 / 1024} MB`);
const patch = changes => emit('update', { ...props.data, ...changes });

const validateFile = file => {
  const accepted = rule.value.accept.split(',');
  const extension = `.${file.name.split('.').pop()?.toLowerCase()}`;
  const validType =
    accepted.includes(file.type) || accepted.includes(extension);
  if (!validType) throw new Error('نوع الملف غير مدعوم لهذه الرسالة.');
  if (file.size > rule.value.maxBytes)
    throw new Error(`حجم الملف يتجاوز الحد المسموح (${maxSizeLabel.value}).`);
};

const uploadFile = event => {
  const file = event.target.files?.[0];
  event.target.value = '';
  if (!file) return;

  try {
    validateFile(file);
  } catch (error) {
    useAlert(error.message);
    return;
  }

  uploadState.value = 'processing';
  const upload = new DirectUpload(
    file,
    `/api/v1/accounts/${accountId.value}/bot_flow_direct_uploads`,
    {
      directUploadWillCreateBlobWithXHR: xhr => setDirectUploadAuthHeaders(xhr),
    }
  );
  upload.create((error, blob) => {
    uploadState.value = error ? 'failed' : 'uploaded';
    if (error) {
      useAlert(error);
      return;
    }
    patch({
      blobSignedId: blob.signed_id,
      filename: blob.filename,
      contentType: blob.content_type,
      byteSize: blob.byte_size,
    });
  });
};

const removeFile = () =>
  patch({ blobSignedId: '', filename: '', contentType: '', byteSize: 0 });
</script>

<template>
  <div class="space-y-5">
    <div>
      <p class="mb-2 text-xs font-medium text-n-slate-12">
        {{ $t('FLOW_BUILDER.SETTINGS.MEDIA_FILE') }}
      </p>
      <label
        class="flex min-h-16 cursor-pointer items-center gap-3 rounded-lg border border-dashed border-n-strong bg-n-background px-3 py-2 text-n-slate-11 hover:bg-n-alpha-2"
        :class="{
          'pointer-events-none opacity-60': uploadState === 'processing',
        }"
      >
        <input
          class="hidden"
          type="file"
          :accept="rule.accept"
          @change="uploadFile"
        />
        <Spinner v-if="uploadState === 'processing'" />
        <span v-else class="i-lucide-upload size-5 shrink-0" />
        <span class="min-w-0 flex-1">
          <span class="block truncate text-sm text-n-slate-12">
            {{ data.filename || $t('FLOW_BUILDER.SETTINGS.SELECT_FILE') }}
          </span>
          <span class="text-xs text-n-slate-9">
            {{
              $t('FLOW_BUILDER.SETTINGS.MAX_FILE_SIZE', { size: maxSizeLabel })
            }}
          </span>
        </span>
        <button
          v-if="data.blobSignedId"
          type="button"
          class="flow-icon-btn"
          :aria-label="$t('FLOW_BUILDER.SETTINGS.REMOVE_FILE')"
          @click.prevent="removeFile"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </label>
    </div>

    <TextArea
      v-if="showCaption && nodeType !== 'audio'"
      :model-value="data.caption"
      :label="$t('FLOW_BUILDER.SETTINGS.CAPTION')"
      :max-length="1024"
      min-height="7rem"
      resize
      show-character-count
      @update:model-value="patch({ caption: $event })"
    />

    <div v-if="nodeType === 'audio'" class="flex items-center gap-3">
      <Switch
        :model-value="Boolean(data.isVoiceMessage)"
        @update:model-value="patch({ isVoiceMessage: $event })"
      />
      <span class="text-sm text-n-slate-12">
        {{ $t('FLOW_BUILDER.SETTINGS.VOICE_MESSAGE') }}
      </span>
    </div>
  </div>
</template>
