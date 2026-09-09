import { computed } from 'vue';
import { useNow } from '@vueuse/core';

const WINDOW_SECONDS = 24 * 60 * 60;

export function useWhatsAppReplyWindow(conversation) {
  const now = useNow({ interval: 1000 });
  const expiresAt = computed(() => {
    const chat = conversation.value;
    const lastIncoming = (chat.messages || [])
      .filter(message => message.message_type === 0 && !message.private)
      .reduce((latest, message) => Math.max(latest, message.created_at), 0);
    return lastIncoming ? lastIncoming + WINDOW_SECONDS : 0;
  });
  const remainingSeconds = computed(() => {
    if (!expiresAt.value) {
      return conversation.value.can_reply ? WINDOW_SECONDS : 0;
    }

    return Math.max(0, Math.ceil(expiresAt.value - now.value.getTime() / 1000));
  });
  const isOpen = computed(
    () => conversation.value.can_reply && remainingSeconds.value > 0
  );
  const countdown = computed(() => {
    const seconds = remainingSeconds.value;
    return [
      Math.floor(seconds / 3600),
      Math.floor((seconds % 3600) / 60),
      seconds % 60,
    ]
      .map(value => String(value).padStart(2, '0'))
      .join(':');
  });
  return { isOpen, countdown };
}
