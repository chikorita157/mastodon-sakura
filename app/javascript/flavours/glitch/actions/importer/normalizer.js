import escapeTextContentForBrowser from 'escape-html';

import emojify from '../../features/emoji/emoji';
import { autoHideCW } from '../../utils/content_warning';

const domParser = new DOMParser();

const makeEmojiMap = emojis => emojis.reduce((obj, emoji) => {
  obj[`:${emoji.shortcode}:`] = emoji;
  return obj;
}, {});

export function searchTextFromRawStatus (status) {
  const spoilerText   = status.spoiler_text || '';
  const searchContent = ([spoilerText, status.content].concat((status.poll && status.poll.options) ? status.poll.options.map(option => option.title) : [])).concat(status.media_attachments.map(att => att.description)).join('\n\n').replace(/<br\s*\/?>/g, '\n').replace(/<\/p><p>/g, '\n\n');
  return domParser.parseFromString(searchContent, 'text/html').documentElement.textContent;
}

export function normalizeFilterResult(result) {
  const normalResult = { ...result };

  normalResult.filter = normalResult.filter.id;

  return normalResult;
}

export function normalizeStatus(status, normalOldStatus, settings) {
  const normalStatus   = { ...status };
  normalStatus.account = status.account.id;

  if (status.reblog && status.reblog.id) {
    normalStatus.reblog = status.reblog.id;
  }

  if (status.poll && status.poll.id) {
    normalStatus.poll = status.poll.id;
  }

  if (status.card) {
    normalStatus.card = {
      ...status.card,
      authors: status.card.authors.map(author => ({
        ...author,
        accountId: author.account?.id,
        account: undefined,
      })),
    };
  }

  if (status.filtered) {
    normalStatus.filtered = status.filtered.map(normalizeFilterResult);
  }

  // Only calculate these values when status first encountered and
  // when the underlying values change. Otherwise keep the ones
  // already in the reducer
  if (normalOldStatus && normalOldStatus.get('content') === normalStatus.content && normalOldStatus.get('spoiler_text') === normalStatus.spoiler_text) {
    normalStatus.search_index = normalOldStatus.get('search_index');
    normalStatus.contentHtml = normalOldStatus.get('contentHtml');
    normalStatus.spoilerHtml = normalOldStatus.get('spoilerHtml');
    normalStatus.hidden = normalOldStatus.get('hidden');
    normalStatus.quote = normalOldStatus.get('quote');
    normalStatus.quote_hidden = normalOldStatus.get('quote_hidden');

    if (normalOldStatus.get('translation')) {
      normalStatus.translation = normalOldStatus.get('translation');
    }
  } else {
    const spoilerText   = normalStatus.spoiler_text || '';
    const searchContent = ([spoilerText, status.content].concat((status.poll && status.poll.options) ? status.poll.options.map(option => option.title) : [])).concat(status.media_attachments.map(att => att.description)).join('\n\n').replace(/<br\s*\/?>/g, '\n').replace(/<\/p><p>/g, '\n\n');
    const emojiMap      = makeEmojiMap(normalStatus.emojis);

    normalStatus.search_index = domParser.parseFromString(searchContent, 'text/html').documentElement.textContent;
    normalStatus.contentHtml  = emojify(normalStatus.content, emojiMap);
    normalStatus.spoilerHtml  = emojify(escapeTextContentForBrowser(spoilerText), emojiMap);
    normalStatus.hidden       = (spoilerText.length > 0 || normalStatus.sensitive) && autoHideCW(settings, spoilerText);

    if (status.quote && status.quote.id) {
      const quote_spoilerText = status.quote.spoiler_text || '';
      const quote_searchContent = [quote_spoilerText, status.quote.content].join('\n\n').replace(/<br\s*\/?>/g, '\n').replace(/<\/p><p>/g, '\n\n');

      const quote_emojiMap = makeEmojiMap(normalStatus.quote.emojis);

      const quote_account_emojiMap = makeEmojiMap(status.quote.account.emojis);
      const displayName = normalStatus.quote.account.display_name.length === 0 ? normalStatus.quote.account.username : normalStatus.quote.account.display_name;
      normalStatus.quote.account.display_name_html = emojify(escapeTextContentForBrowser(displayName), quote_account_emojiMap);
      normalStatus.quote.search_index = domParser.parseFromString(quote_searchContent, 'text/html').documentElement.textContent;
      let docElem = domParser.parseFromString(normalStatus.quote.content, 'text/html').documentElement;
      Array.from(docElem.querySelectorAll('span.quote-inline'), span => span.remove());
      Array.from(docElem.querySelectorAll('p,br'), line => {
        let parentNode = line.parentNode;
        if (line.nextSibling) {
          parentNode.insertBefore(document.createTextNode(' '), line.nextSibling);
        }
      });
      let _contentHtml = docElem.textContent;
      normalStatus.quote.contentHtml  = '<p>'+emojify(_contentHtml.substr(0, 150), quote_emojiMap) + (_contentHtml.substr(150) ? '...' : '')+'</p>';
      normalStatus.quote.spoilerHtml  = emojify(escapeTextContentForBrowser(quote_spoilerText), quote_emojiMap);
      normalStatus.quote_hidden       = (quote_spoilerText.length > 0 || normalStatus.quote.sensitive) && autoHideCW(settings, quote_spoilerText);

      // delete the quote link!!!!
      let parentDocElem = domParser.parseFromString(normalStatus.contentHtml, 'text/html').documentElement;
      Array.from(parentDocElem.querySelectorAll('span.quote-inline'), span => span.remove());
      normalStatus.contentHtml = parentDocElem.children[1].innerHTML;
    }
  }

  if (normalOldStatus) {
    const list = normalOldStatus.get('media_attachments');
    if (normalStatus.media_attachments && list) {
      normalStatus.media_attachments.forEach(item => {
        const oldItem = list.find(i => i.get('id') === item.id);
        if (oldItem && oldItem.get('description') === item.description) {
          item.translation = oldItem.get('translation');
        }
      });
    }
  }

  return normalStatus;
}

export function normalizeStatusTranslation(translation, status) {
  const emojiMap = makeEmojiMap(status.get('emojis').toJS());

  const normalTranslation = {
    detected_source_language: translation.detected_source_language,
    language: translation.language,
    provider: translation.provider,
    contentHtml: emojify(translation.content, emojiMap),
    spoilerHtml: emojify(escapeTextContentForBrowser(translation.spoiler_text), emojiMap),
    spoiler_text: translation.spoiler_text,
  };

  return normalTranslation;
}

export function normalizePoll(poll, normalOldPoll) {
  const normalPoll = { ...poll };
  const emojiMap = makeEmojiMap(poll.emojis);

  normalPoll.options = poll.options.map((option, index) => {
    const normalOption = {
      ...option,
      voted: poll.own_votes && poll.own_votes.includes(index),
      titleHtml: emojify(escapeTextContentForBrowser(option.title), emojiMap),
    };

    if (normalOldPoll && normalOldPoll.getIn(['options', index, 'title']) === option.title) {
      normalOption.translation = normalOldPoll.getIn(['options', index, 'translation']);
    }

    return normalOption;
  });

  return normalPoll;
}

export function normalizePollOptionTranslation(translation, poll) {
  const emojiMap = makeEmojiMap(poll.get('emojis').toJS());

  const normalTranslation = {
    ...translation,
    titleHtml: emojify(escapeTextContentForBrowser(translation.title), emojiMap),
  };

  return normalTranslation;
}

export function normalizeAnnouncement(announcement) {
  const normalAnnouncement = { ...announcement };
  const emojiMap = makeEmojiMap(normalAnnouncement.emojis);

  normalAnnouncement.contentHtml = emojify(normalAnnouncement.content, emojiMap);

  return normalAnnouncement;
}
