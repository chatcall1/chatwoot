<script>
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { generateRelativeTime } from 'shared/helpers/DateHelper';

export default {
  name: 'TimeAgo',
  props: {
    isAutoRefreshEnabled: {
      type: Boolean,
      default: true,
    },
    lastActivityTimestamp: {
      type: [String, Date, Number],
      default: '',
    },
    createdAtTimestamp: {
      type: [String, Date, Number],
      default: '',
    },
    conversationId: {
      type: [String, Number],
      default: '',
    },
  },
  data() {
    return {
      lastActivityAtTimeAgo: dynamicTime(this.lastActivityTimestamp),
      createdAtTimeAgo: dynamicTime(this.createdAtTimestamp),
      timer: null,
    };
  },
  computed: {
    lastActivityTime() {
      if (!this.lastActivityAtTimeAgo) return '';

      return this.localizedTimeAgo(this.lastActivityTimestamp);
    },
    createdAtTime() {
      // Kept for a possible return to displaying the conversation creation time.
      return shortTimestamp(this.createdAtTimeAgo);
    },
    createdAt() {
      if (!this.createdAtTimeAgo) return '';

      const createdTimeDiff = Date.now() - this.createdAtTimestamp * 1000;
      const isBeforeAMonth = createdTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isBeforeAMonth
        ? `${this.$t(
            'CHAT_LIST.CHAT_TIME_STAMP.CREATED.LATEST'
          )} ${this.localizedTimeAgo(this.createdAtTimestamp)}`
        : `${this.$t(
            'CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST'
          )} ${this.localizedDate(this.createdAtTimestamp)}`;
    },
    lastActivity() {
      if (!this.lastActivityAtTimeAgo) return '';

      const lastActivityTimeDiff =
        Date.now() - this.lastActivityTimestamp * 1000;
      const isNotActive = lastActivityTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isNotActive
        ? `${this.$t(
            'CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.ACTIVE'
          )} ${this.localizedTimeAgo(this.lastActivityTimestamp)}`
        : `${this.$t(
            'CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE'
          )} ${this.localizedDate(this.lastActivityTimestamp)}`;
    },
    tooltipText() {
      return `${this.createdAt}\n${this.lastActivity}`;
    },
  },
  watch: {
    lastActivityTimestamp() {
      this.lastActivityAtTimeAgo = dynamicTime(this.lastActivityTimestamp);
    },
    createdAtTimestamp() {
      this.createdAtTimeAgo = dynamicTime(this.createdAtTimestamp);
    },
    conversationId() {
      // Reset display values and timer when the row is recycled to a different conversation.
      this.lastActivityAtTimeAgo = dynamicTime(this.lastActivityTimestamp);
      this.createdAtTimeAgo = dynamicTime(this.createdAtTimestamp);
      if (this.isAutoRefreshEnabled) {
        clearTimeout(this.timer);
        this.createTimer();
      }
    },
  },
  mounted() {
    if (this.isAutoRefreshEnabled) {
      this.createTimer();
    }
  },
  unmounted() {
    clearTimeout(this.timer);
  },
  methods: {
    localizedTimeAgo(timestamp) {
      const elapsedSeconds = Math.max(
        0,
        Math.floor(Date.now() / 1000 - timestamp)
      );

      if (elapsedSeconds < 60) {
        return generateRelativeTime(0, 'second', this.$i18n.locale);
      }
      if (elapsedSeconds < 3600) {
        return generateRelativeTime(
          -Math.floor(elapsedSeconds / 60),
          'minute',
          this.$i18n.locale
        );
      }
      if (elapsedSeconds < 86400) {
        return generateRelativeTime(
          -Math.floor(elapsedSeconds / 3600),
          'hour',
          this.$i18n.locale
        );
      }
      return generateRelativeTime(
        -Math.floor(elapsedSeconds / 86400),
        'day',
        this.$i18n.locale
      );
    },
    localizedDate(timestamp) {
      return new Intl.DateTimeFormat(this.$i18n.locale, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      }).format(new Date(timestamp * 1000));
    },
    createTimer() {
      this.timer = setTimeout(() => {
        this.lastActivityAtTimeAgo = dynamicTime(this.lastActivityTimestamp);
        this.createdAtTimeAgo = dynamicTime(this.createdAtTimestamp);
        this.createTimer();
      }, this.refreshTime());
    },
    refreshTime() {
      const timeDiff = Date.now() - this.lastActivityTimestamp * 1000;
      if (timeDiff > DAY_IN_MILLI_SECONDS) {
        return DAY_IN_MILLI_SECONDS;
      }
      if (timeDiff > HOUR_IN_MILLI_SECONDS) {
        return HOUR_IN_MILLI_SECONDS;
      }

      return MINUTE_IN_MILLI_SECONDS;
    },
  },
};
</script>

<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      delay: { show: 1000, hide: 0 },
    }"
    class="ml-auto leading-4 text-xxs text-n-activity"
  >
    <!-- createdAtTime is intentionally retained for possible future reuse. -->
    <span>{{ lastActivityTime }}</span>
  </div>
</template>
