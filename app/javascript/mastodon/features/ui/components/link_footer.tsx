import { FormattedMessage } from 'react-intl';

import { Link } from 'react-router-dom';

import {
  domain,
  version,
  source_url,
  statusPageUrl,
  profile_directory as canProfileDirectory,
  termsOfServiceEnabled,
} from 'mastodon/initial_state';

const DividingCircle: React.FC = () => <span aria-hidden>{' · '}</span>;

export const LinkFooter: React.FC<{
  multiColumn: boolean;
}> = ({ multiColumn }) => {
  return (
    <div className='link-footer'>
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
      <strong>{domain}</strong>:{' '}
      <Link to='/about' target={multiColumn ? '_blank' : undefined}>
        <FormattedMessage id='footer.about' defaultMessage='About' />
      </Link>
      {' · '}
      <a key='misskey' href='https://sakurajima.social'>Misskey</a>
      {' · '}
      <a key='forums' href='https://forums.sakurajima.moe'>Forums</a>
      {' · '}
      <a key='blog' href='https://blog.sakurajima.moe'>Blog</a>
        {statusPageUrl && (
          <>
            <DividingCircle />
            <a href={statusPageUrl} target='_blank' rel='noopener'>
              <FormattedMessage id='footer.status' defaultMessage='Status' />
            </a>
          </>
        )}
        {canProfileDirectory && (
          <>
            <DividingCircle />
            <Link to='/directory'>
              <FormattedMessage
                id='footer.directory'
                defaultMessage='Profiles directory'
              />
            </Link>
          </>
        )}
        <DividingCircle />
        <Link
          to='/privacy-policy'
          target={multiColumn ? '_blank' : undefined}
          rel='privacy-policy'
        >
          <FormattedMessage
            id='footer.privacy_policy'
            defaultMessage='Privacy policy'
          />
        </Link>
        {termsOfServiceEnabled && (
          <>
            <DividingCircle />
            <Link
              to='/terms-of-service'
              target={multiColumn ? '_blank' : undefined}
              rel='terms-of-service'
            >
              <FormattedMessage
                id='footer.terms_of_service'
                defaultMessage='Terms of service'
              />
            </Link>
          </>
        )}
      </p>

      <p>
        <strong>Mastodon</strong>:{' '}
        <a href='https://joinmastodon.org' target='_blank' rel='noopener'>
          <FormattedMessage id='footer.about' defaultMessage='About' />
        </a>
        <DividingCircle />
        <a href='https://joinmastodon.org/apps' target='_blank' rel='noopener'>
          <FormattedMessage id='footer.get_app' defaultMessage='Get the app' />
        </a>
        <DividingCircle />
        <Link to='/keyboard-shortcuts'>
          <FormattedMessage
            id='footer.keyboard_shortcuts'
            defaultMessage='Keyboard shortcuts'
          />
        </Link>
        <DividingCircle />
        <a href={source_url} rel='noopener' target='_blank'>
          <FormattedMessage
            id='footer.source_code'
            defaultMessage='View source code'
          />
        </a>
        <DividingCircle />
        <span className='version'>v{version}</span>
      </p>
    </div>
  );
};
