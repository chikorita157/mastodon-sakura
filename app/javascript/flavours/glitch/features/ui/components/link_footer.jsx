import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { FormattedMessage, injectIntl } from 'react-intl';

import { Link } from 'react-router-dom';

import { connect } from 'react-redux';

import { openModal } from 'flavours/glitch/actions/modal';
import { identityContextPropShape, withIdentity } from 'flavours/glitch/identity_context';
import { domain, version, source_url, statusPageUrl, profile_directory as profileDirectory } from 'flavours/glitch/initial_state';
import { PERMISSION_INVITE_USERS } from 'flavours/glitch/permissions';

const mapDispatchToProps = (dispatch) => ({
  onLogout () {
    dispatch(openModal({ modalType: 'CONFIRM_LOG_OUT' }));

  },
});

class LinkFooter extends PureComponent {
  static propTypes = {
  identity: identityContextPropShape,
  multiColumn: PropTypes.bool,
  onLogout: PropTypes.func.isRequired,
  intl: PropTypes.object.isRequired,
  };

  handleLogoutClick = e => {
  e.preventDefault();
  e.stopPropagation();

  this.props.onLogout();

  return false;
  };

  render () {
  const { signedIn, permissions } = this.props.identity;
  const { multiColumn } = this.props;

  const canInvite = signedIn && ((permissions & PERMISSION_INVITE_USERS) === PERMISSION_INVITE_USERS);
  const canProfileDirectory = profileDirectory;

  const DividingCircle = <span aria-hidden>{' · '}</span>;

  return (
    <div className='link-footer'>
    <p>
      Used to Twitter and Mastodon FE too hard? Try our <a href="https://elk.sakurajima.moe/">Elk Frontend</a>
    </p>
    <p>
      <strong>Sakurajima is a donor sponsored instance.</strong> You can support us at:
      {' '}
       <a key='paypal' href='https://www.paypal.com/donate/?hosted_button_id=HREN4ATRLZ54S'>Paypal</a>
      {' · '}
      <a key='kofi' href='https://ko-fi.com/V7V8GAJR9'>Ko-Fi</a>
      {' · '}
      <a key='patreon' href='https://www.patreon.com/sakurajimamastodon'>Patreon</a>
      </p>
    <p>
      <strong>{domain}</strong>:
      {' '}
      <Link to='/about' target={multiColumn ? '_blank' : undefined}><FormattedMessage id='footer.about' defaultMessage='About' /></Link>
      {' · '}
      <a key='misskey' href='https://sakurajima.social'>Misskey</a>
      {' · '}
      <a key='forums' href='https://forums.sakurajima.moe'>Forums</a>
      {' · '}
      <a key='blog' href='https://blog.sakurajima.moe'>Blog</a>
      {statusPageUrl && (
      <>
        {DividingCircle}
        <a href={statusPageUrl} target='_blank' rel='noopener'><FormattedMessage id='footer.status' defaultMessage='Status' /></a>
      </>
      )}
      {canInvite && (
      <>
        {DividingCircle}
        <a href='/invites' target='_blank'><FormattedMessage id='footer.invite' defaultMessage='Invite people' /></a>
      </>
      )}
      {canProfileDirectory && (
      <>
        {DividingCircle}
        <Link to='/directory'><FormattedMessage id='footer.directory' defaultMessage='Profiles directory' /></Link>
      </>
      )}
      {DividingCircle}
      <Link to='/privacy-policy' target={multiColumn ? '_blank' : undefined}><FormattedMessage id='footer.privacy_policy' defaultMessage='Privacy policy' /></Link>
    </p>

    <p>
      <strong>Mastodon</strong>:
      {' '}
      <a href='https://joinmastodon.org' target='_blank'><FormattedMessage id='footer.about' defaultMessage='About' /></a>
      {DividingCircle}
      <a href='https://joinmastodon.org/apps' target='_blank'><FormattedMessage id='footer.get_app' defaultMessage='Get the app' /></a>
      {DividingCircle}
      <Link to='/keyboard-shortcuts'><FormattedMessage id='footer.keyboard_shortcuts' defaultMessage='Keyboard shortcuts' /></Link>
      {DividingCircle}
      <a href={source_url} rel='noopener noreferrer' target='_blank'><FormattedMessage id='footer.source_code' defaultMessage='View source code' /></a>
      {DividingCircle}
      <span className='version'>v{version}</span>
    </p>
    </div>
  );
  }

}

export default injectIntl(withIdentity(connect(null, mapDispatchToProps)(LinkFooter)));
