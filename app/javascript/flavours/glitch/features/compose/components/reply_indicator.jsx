import { FormattedMessage } from 'react-intl';

import { useSelector } from 'react-redux';

import BarChart4BarsIcon from '@/material-icons/400-24px/bar_chart_4_bars.svg?react';
import QuoteIcon from '@/material-icons/400-24px/format_quote-fill.svg?react';
import PhotoLibraryIcon from '@/material-icons/400-24px/photo_library.svg?react';
import { Avatar } from 'flavours/glitch/components/avatar';
import { DisplayName } from 'flavours/glitch/components/display_name';
import { Icon } from 'flavours/glitch/components/icon';
import { Permalink } from 'flavours/glitch/components/permalink';
import { EmbeddedStatusContent } from 'flavours/glitch/features/notifications_v2/components/embedded_status_content';

export const ReplyIndicator = () => {
  const inReplyToId = useSelector(state => state.getIn(['compose', 'in_reply_to']));
  const quoteId = useSelector(state => state.getIn(['compose', 'quote_id']));
  const status = useSelector(state => state.getIn(['statuses', inReplyToId || quoteId]));
  const account = useSelector(state => state.getIn(['accounts', status?.get('account')]));

  if (!status) {
    return null;
  }

  return (
    <div className='reply-indicator'>
      {inReplyToId && (<div className='reply-indicator__line' />)}

      <Permalink href={account.get('url')} to={`/@${account.get('acct')}`} className='detailed-status__display-avatar'>
        <Avatar account={account} size={46} />
      </Permalink>

      <div className='reply-indicator__main'>
        {quoteId && (
          <Icon
            fixedWidth
            aria-hidden='true'
            key='icon-quote-right'
            icon={QuoteIcon} />
        )}
        <Permalink href={account.get('url')} to={`/@${account.get('acct')}`} className='detailed-status__display-name'>
          <DisplayName account={account} />
        </Permalink>

        <EmbeddedStatusContent
          className='reply-indicator__content translate'
          content={status.get('contentHtml')}
          language={status.get('language')}
          mentions={status.get('mentions')}
        />

        {(status.get('poll') || status.get('media_attachments').size > 0) && (
          <div className='reply-indicator__attachments'>
            {status.get('poll') && <><Icon icon={BarChart4BarsIcon} /><FormattedMessage id='reply_indicator.poll' defaultMessage='Poll' /></>}
            {status.get('media_attachments').size > 0 && <><Icon icon={PhotoLibraryIcon} /><FormattedMessage id='reply_indicator.attachments' defaultMessage='{count, plural, one {# attachment} other {# attachments}}' values={{ count: status.get('media_attachments').size }} /></>}
          </div>
        )}
      </div>
    </div>
  );
};
