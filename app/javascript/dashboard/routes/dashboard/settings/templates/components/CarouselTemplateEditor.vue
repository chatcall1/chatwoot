<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import FileUpload from 'vue-upload-component';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  bodyVariableIndexes: { type: Array, required: true },
  activeCardVariableIndexes: { type: Array, required: true },
  activeCardIndex: { type: Number, required: true },
  carouselMediaAccept: { type: String, required: true },
  carouselActionTypes: { type: Array, required: true },
  carouselActionByValue: { type: Object, required: true },
  isCardComplete: { type: Function, required: true },
  carouselActionError: { type: Function, required: true },
  variableIndexes: { type: Function, required: true },
});
defineEmits([
  'addBodyVariable',
  'setMediaType',
  'setCardElement',
  'selectCard',
  'addCard',
  'deleteCard',
  'duplicateCard',
  'navigateCard',
  'handleCardFile',
  'addCardVariable',
  'toggleAction',
  'normalizePhoneNumber',
]);
const state = defineModel('state', { type: Object, required: true });
const activeCard = computed(() => state.value.cards[props.activeCardIndex]);
const { t } = useI18n();
</script>

<template>
  <div class="grid gap-3 p-4 border-2 rounded-xl border-n-slate-8 bg-n-alpha-1">
    <div class="flex items-center justify-between gap-3">
      <span>
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ t('WHATSAPP_TEMPLATE_BUILDER.SECTIONS.BODY') }}
        </h3>
        <p class="mt-1 text-xs text-n-slate-10">
          {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.BODY_HELPER') }}
        </p>
      </span>
      <Button
        :label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_VARIABLE')"
        icon="i-lucide-braces"
        color="teal"
        variant="ghost"
        size="sm"
        @click="$emit('addBodyVariable')"
      />
    </div>
    <Editor
      v-model="state.body"
      :placeholder="t('WHATSAPP_TEMPLATE_BUILDER.BODY.PLACEHOLDER')"
      :max-length="1024"
      channel-type="Context::WhatsappTemplate"
    />
    <div v-if="bodyVariableIndexes.length" class="grid gap-3 sm:grid-cols-2">
      <Input
        v-for="index in bodyVariableIndexes"
        :key="index"
        v-model="state.bodyExamples[index]"
        :label="
          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE', {
            n: index,
          })
        "
        :placeholder="
          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE_PLACEHOLDER')
        "
      />
    </div>
  </div>
  <div
    class="flex flex-col gap-5 p-4 border rounded-xl border-n-strong bg-n-alpha-1"
  >
    <div class="flex items-center justify-between gap-3">
      <div>
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.TITLE') }}
        </h3>
        <p class="mt-1 text-xs text-n-slate-10">
          {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.DESCRIPTION') }}
        </p>
      </div>
      <span class="text-xs text-n-slate-10">
        {{
          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.COUNT', {
            current: state.cards.length,
          })
        }}
      </span>
    </div>
    <div
      class="flex flex-wrap items-center justify-between gap-3 p-3 rounded-lg bg-n-alpha-2"
    >
      <div class="flex items-center gap-2">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.MEDIA') }}
        </span>
        <Button
          :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.IMAGE')"
          icon="i-lucide-image"
          size="sm"
          :variant="state.carouselMediaType === 'image' ? 'solid' : 'ghost'"
          :color="state.carouselMediaType === 'image' ? 'teal' : 'slate'"
          @click="$emit('setMediaType', 'image')"
        />
        <Button
          :label="t('WHATSAPP_TEMPLATE_BUILDER.HEADER.TYPES.VIDEO')"
          icon="i-lucide-video"
          size="sm"
          :variant="state.carouselMediaType === 'video' ? 'solid' : 'ghost'"
          :color="state.carouselMediaType === 'video' ? 'teal' : 'slate'"
          @click="$emit('setMediaType', 'video')"
        />
      </div>
      <label
        class="flex items-center gap-2 text-xs font-medium cursor-pointer text-n-slate-11"
      >
        <Switch v-model="state.carouselTextEnabled" />
        {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_TEXT') }}
      </label>
    </div>
    <div class="flex gap-3 pb-2 overflow-x-auto">
      <button
        v-for="(card, index) in state.cards"
        :key="card.id"
        :ref="element => $emit('setCardElement', card.id, element)"
        type="button"
        class="w-36 overflow-hidden text-start border-2 rounded-xl shrink-0 bg-n-alpha-3 transition-colors"
        :class="
          activeCardIndex === index
            ? 'border-[#00a884] shadow-sm'
            : 'border-[#cbd5e1] hover:border-[#94a3b8]'
        "
        @click="$emit('selectCard', index)"
      >
        <div class="grid h-20 place-items-center bg-n-alpha-2">
          <img
            v-if="card.mediaUrl && card.mediaMimeType.startsWith('image/')"
            :src="card.mediaUrl"
            class="object-cover w-full h-full"
          />
          <video
            v-else-if="state.headerType === 'video' && state.headerMediaUrl"
            :src="state.headerMediaUrl"
            class="object-cover w-full h-full"
            autoplay
            loop
            muted
          />
          <video
            v-else-if="card.mediaUrl"
            :src="card.mediaUrl"
            class="object-cover w-full h-full"
            muted
          />
          <Icon v-else icon="i-lucide-image" class="size-6 text-n-slate-10" />
        </div>
        <p class="p-2 text-xs font-medium text-n-slate-12">
          {{
            t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD', {
              n: index + 1,
            })
          }}
        </p>
        <p class="px-2 pb-2 text-[0.65rem] text-n-slate-10">
          {{
            isCardComplete(card)
              ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.COMPLETE')
              : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.INCOMPLETE')
          }}
        </p>
      </button>
      <button
        v-if="state.cards.length < 10"
        type="button"
        class="grid w-28 border border-dashed rounded-xl shrink-0 min-h-28 place-items-center border-n-strong text-n-slate-10 hover:border-n-brand hover:text-n-brand"
        @click="$emit('addCard')"
      >
        <span class="flex flex-col items-center gap-2 text-xs">
          <Icon icon="i-lucide-plus" class="size-5" />
          {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_CARD') }}
        </span>
      </button>
    </div>
    <div class="flex items-center gap-1 py-2 border-t border-n-weak">
      <Button
        icon="i-lucide-trash-2"
        color="slate"
        variant="ghost"
        size="sm"
        :disabled="state.cards.length <= 2"
        :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.DELETE_CARD')"
        @click="$emit('deleteCard')"
      />
      <Button
        icon="i-lucide-copy"
        color="slate"
        variant="ghost"
        size="sm"
        :disabled="state.cards.length >= 10"
        :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.DUPLICATE_CARD')"
        @click="$emit('duplicateCard')"
      />
      <Button
        icon="i-lucide-chevron-left"
        color="slate"
        variant="ghost"
        size="sm"
        :disabled="activeCardIndex === 0"
        :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.PREVIOUS_CARD')"
        @click="$emit('navigateCard', -1)"
      />
      <Button
        icon="i-lucide-chevron-right"
        color="slate"
        variant="ghost"
        size="sm"
        :disabled="activeCardIndex === state.cards.length - 1"
        :aria-label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.NEXT_CARD')"
        @click="$emit('navigateCard', 1)"
      />
    </div>
    <div class="grid gap-4 pt-4 border-t border-n-weak">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{
          t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD', {
            n: activeCardIndex + 1,
          })
        }}
      </h4>
      <p class="-mt-3 text-xs text-n-slate-10">
        {{
          isCardComplete(activeCard)
            ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.COMPLETE')
            : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.INCOMPLETE')
        }}
      </p>
      <FileUpload
        :input-id="`whatsappCarouselCard${activeCardIndex}`"
        :accept="carouselMediaAccept"
        :size="(state.carouselMediaType === 'video' ? 16 : 5) * 1024 * 1024"
        :multiple="false"
        :drop-directory="false"
        @input-file="file => $emit('handleCardFile', file, activeCardIndex)"
      >
        <div
          class="flex items-center justify-between p-4 transition-colors border-2 border-dashed cursor-pointer rounded-xl border-n-slate-8 hover:border-n-slate-10"
        >
          <span class="text-sm text-n-slate-12">
            {{
              state.cards[activeCardIndex].mediaName ||
              t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.UPLOAD_MEDIA')
            }}
          </span>
          <Icon icon="i-lucide-upload" class="size-5" />
        </div>
      </FileUpload>
      <p class="-mt-3 text-xs text-n-slate-10">
        {{
          state.carouselMediaType === 'video'
            ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VIDEO_HELPER')
            : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.IMAGE_HELPER')
        }}
      </p>
      <div v-if="state.carouselTextEnabled" class="grid gap-2">
        <div class="flex items-center justify-between gap-2">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_BODY') }}
          </span>
          <span class="flex items-center gap-3">
            <Button
              :label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ADD_VARIABLE')"
              icon="i-lucide-braces"
              color="teal"
              variant="ghost"
              size="sm"
              @click="$emit('addCardVariable')"
            />
            <span class="text-xs text-n-slate-10">
              {{
                t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.TEXT_COUNT', {
                  current: activeCard.body.length,
                })
              }}
            </span>
          </span>
        </div>
        <Editor
          v-model="activeCard.body"
          :placeholder="
            t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.CARD_BODY_PLACEHOLDER')
          "
          :max-length="160"
          channel-type="Context::WhatsappTemplate"
        />
        <div
          v-if="activeCardVariableIndexes.length"
          class="grid gap-3 sm:grid-cols-2"
        >
          <Input
            v-for="index in activeCardVariableIndexes"
            :key="index"
            v-model="activeCard.bodyExamples[index]"
            :label="
              t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE', {
                n: index,
              })
            "
            :placeholder="
              t(
                'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.VARIABLE_EXAMPLE_PLACEHOLDER'
              )
            "
          />
        </div>
      </div>
      <div class="grid gap-3 pt-4 border-t border-n-weak">
        <div>
          <h4 class="text-sm font-semibold text-n-slate-12">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.TITLE') }}
          </h4>
          <p class="mt-1 text-xs text-n-slate-10">
            {{ t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.DESCRIPTION') }}
          </p>
        </div>
        <div class="grid gap-2 sm:grid-cols-3">
          <Button
            v-for="action in carouselActionTypes"
            :key="action.value"
            :label="action.label"
            :icon="action.icon"
            size="sm"
            :variant="
              state.carouselButtonTypes.includes(action.value)
                ? 'solid'
                : 'outline'
            "
            :color="
              state.carouselButtonTypes.includes(action.value)
                ? 'teal'
                : 'slate'
            "
            :disabled="
              state.carouselButtonTypes.length >= 2 &&
              !state.carouselButtonTypes.includes(action.value)
            "
            @click="$emit('toggleAction', action.value)"
          />
        </div>
        <div
          v-for="action in state.carouselButtonTypes"
          :key="action"
          class="grid gap-3 p-3 border rounded-lg border-n-strong sm:grid-cols-2"
        >
          <Input
            v-model="activeCard.buttons[action].text"
            :label="carouselActionByValue[action].label"
            :placeholder="
              t('WHATSAPP_TEMPLATE_BUILDER.BUTTONS.TEXT_PLACEHOLDER')
            "
            maxlength="25"
            :message="
              activeCard.buttons[action].text.length
                ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.TEXT_HELPER', {
                    current: activeCard.buttons[action].text.length,
                  })
                : ''
            "
          />
          <Input
            v-if="action !== 'QUICK_REPLY'"
            v-model="activeCard.buttons[action].value"
            :type="action === 'PHONE_NUMBER' ? 'tel' : 'url'"
            :label="carouselActionByValue[action].valueLabel"
            :placeholder="carouselActionByValue[action].valuePlaceholder"
            :message="
              carouselActionError(action) ||
              (action === 'PHONE_NUMBER'
                ? t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.PHONE_HELPER')
                : t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_HELPER'))
            "
            :message-type="carouselActionError(action) ? 'error' : 'info'"
            dir="ltr"
            @input="
              action === 'PHONE_NUMBER' && $emit('normalizePhoneNumber', $event)
            "
          />
          <Input
            v-if="
              action === 'URL' &&
              variableIndexes(activeCard.buttons.URL.value).length
            "
            v-model="activeCard.buttons.URL.example"
            :label="t('WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_EXAMPLE')"
            :placeholder="
              t(
                'WHATSAPP_TEMPLATE_BUILDER.CAROUSEL.ACTIONS.URL_EXAMPLE_PLACEHOLDER'
              )
            "
          />
        </div>
      </div>
    </div>
  </div>
</template>
