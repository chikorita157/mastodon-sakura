import PropTypes from 'prop-types';

import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';

import classNames from 'classnames';

import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';

import { EmptyAccount } from 'flavours/glitch/components/empty_account';
import { ShortNumber } from 'flavours/glitch/components/short_number';
import { VerifiedBadge } from 'flavours/glitch/components/verified_badge';

import { me } from '../initial_state';

import { Avatar } from './avatar';
import { AvatarOverlay } from './avatar_overlay';
import { Button } from './button';
import { FollowersCounter } from './counters';
import { DisplayName } from './display_name';
import { Permalink } from './permalink';
import { RelativeTimestamp } from './relative_timestamp';

const messages = defineMessages({
  follow: { id: 'account.follow', defaultMessage: 'Follow' },
  unfollow: { id: 'account.unfollow', defaultMessage: 'Unfollow' },
  cancel_follow_request: { id: 'account.cancel_follow_request', defaultMessage: 'Withdraw follow request' },
  unblock: { id: 'account.unblock_short', defaultMessage: 'Unblock' },
  unmute: { id: 'account.unmute_short', defaultMessage: 'Unmute' },
  mute_notifications: { id: 'account.mute_notifications_short', defaultMessage: 'Mute notifications' },
  unmute_notifications: { id: 'account.unmute_notifications_short', defaultMessage: 'Unmute notifications' },
  mute: { id: 'account.mute_short', defaultMessage: 'Mute' },
  block: { id: 'account.block_short', defaultMessage: 'Block' },
});

class Account extends ImmutablePureComponent {

  static propTypes = {
    size: PropTypes.number,
    account: ImmutablePropTypes.record,
    onFollow: PropTypes.func.isRequired,
    onBlock: PropTypes.func.isRequired,
    onMute: PropTypes.func.isRequired,
    onMuteNotifications: PropTypes.func.isRequired,
    intl: PropTypes.object.isRequired,
    overlayEmoji: PropTypes.object,
    hidden: PropTypes.bool,
    minimal: PropTypes.bool,
    defaultAction: PropTypes.string,
    withBio: PropTypes.bool,
  };

  static defaultProps = {
    size: 46,
    overlayEmoji: { name: null }
  };

  handleFollow = () => {
    this.props.onFollow(this.props.account);
  };

  handleBlock = () => {
    this.props.onBlock(this.props.account);
  };

  handleMute = () => {
    this.props.onMute(this.props.account);
  };

  handleMuteNotifications = () => {
    this.props.onMuteNotifications(this.props.account, true);
  };

  handleUnmuteNotifications = () => {
    this.props.onMuteNotifications(this.props.account, false);
  };

  render () {
    const { account, intl, hidden, withBio, defaultAction, overlayEmoji, size, minimal } = this.props;

    if (!account) {
      return <EmptyAccount size={size} minimal={minimal} />;
    }

    if (hidden) {
      return (
        <>
          {account.get('display_name')}
          {account.get('username')}
        </>
      );
    }

    let buttons;

    if (account.get('id') !== me && account.get('relationship', null) !== null) {
      const following = account.getIn(['relationship', 'following']);
      const requested = account.getIn(['relationship', 'requested']);
      const blocking  = account.getIn(['relationship', 'blocking']);
      const muting  = account.getIn(['relationship', 'muting']);

      if (requested) {
        buttons = <Button text={intl.formatMessage(messages.cancel_follow_request)} onClick={this.handleFollow} />;
      } else if (blocking) {
        buttons = <Button text={intl.formatMessage(messages.unblock)} onClick={this.handleBlock} />;
      } else if (muting) {
        let hidingNotificationsButton;

        if (account.getIn(['relationship', 'muting_notifications'])) {
          hidingNotificationsButton = <Button text={intl.formatMessage(messages.unmute_notifications)} onClick={this.handleUnmuteNotifications} />;
        } else {
          hidingNotificationsButton = <Button text={intl.formatMessage(messages.mute_notifications)} onClick={this.handleMuteNotifications} />;
        }

        buttons = (
          <>
            <Button text={intl.formatMessage(messages.unmute)} onClick={this.handleMute} />
            {hidingNotificationsButton}
          </>
        );
      } else if (defaultAction === 'mute') {
        buttons = <Button title={intl.formatMessage(messages.mute)} onClick={this.handleMute} />;
      } else if (defaultAction === 'block') {
        buttons = <Button text={intl.formatMessage(messages.block)} onClick={this.handleBlock} />;
      } else if (!account.get('suspended') && !account.get('moved') || following) {
        buttons = <Button text={intl.formatMessage(following ? messages.unfollow : messages.follow)} onClick={this.handleFollow} />;
      }
    }

    let muteTimeRemaining;

    if (account.get('mute_expires_at')) {
      muteTimeRemaining = <>· <RelativeTimestamp timestamp={account.get('mute_expires_at')} futureDate /></>;
    }

    let verification;

    const firstVerifiedField = account.get('fields').find(item => !!item.get('verified_at'));

    if (firstVerifiedField) {
      verification = <VerifiedBadge link={firstVerifiedField.get('value')} />;
    }

    let statusAvatar;
    if (!overlayEmoji.name) {
      statusAvatar = <Avatar account={account} size={size} />;
    } else {
      statusAvatar = <AvatarOverlay account={account} emoji={overlayEmoji} baseSize={size} />;
    }

    return (
      <div className={classNames('account', { 'account--minimal': minimal })}>
        <div className='account__wrapper'>
          <Permalink key={account.get('id')} className='account__display-name' title={account.get('acct')} href={account.get('url')} to={`/@${account.get('acct')}`}>
            <div className='account__avatar-wrapper'>
              {statusAvatar}
            </div>

            <div className='account__contents'>
              <DisplayName account={account} inline />
              {!minimal && (
                <div className='account__details'>
                  {account.get('followers_count') !== -1 && (
                    <ShortNumber value={account.get('followers_count')} renderer={FollowersCounter} />
                  )} {verification} {muteTimeRemaining}
                </div>
              )}
            </div>
          </Permalink>

          {!minimal && (
            <div className='account__relationship'>
              {buttons}
            </div>
          )}
        </div>

        {withBio && (account.get('note').length > 0 ? (
          <div
            className='account__note translate'
            dangerouslySetInnerHTML={{ __html: account.get('note_emojified') }}
          />
        ) : (
          <div className='account__note account__note--missing'><FormattedMessage id='account.no_bio' defaultMessage='No description provided.' /></div>
        ))}
      </div>
    );
  }

}

export default injectIntl(Account);
