import { useCallback } from 'react';

import { FormattedMessage } from 'react-intl';


import { openModal } from 'flavours/glitch/actions/modal';
import { registrationsOpen, sso_redirect } from 'flavours/glitch/initial_state';
import { useAppDispatch, useAppSelector } from 'flavours/glitch/store';

const SignInBanner = () => {
  const dispatch = useAppDispatch();

  const openClosedRegistrationsModal = useCallback(
  () => dispatch(openModal({ modalType: 'CLOSED_REGISTRATIONS' })),
  [dispatch],
  );

  let signupButton;

  const signupUrl = useAppSelector((state) => state.getIn(['server', 'server', 'registrations', 'url'], null) || '/auth/sign_up');

  if (sso_redirect) {
  return (
    <div className='sign-in-banner'>
    <p><strong><FormattedMessage id='sign_in_banner.mastodon_is' defaultMessage="Mastodon is the best way to keep up with what's happening." /></strong></p>
    <p><FormattedMessage id='sign_in_banner.follow_anyone' defaultMessage='Follow anyone across the fediverse and see it all in chronological order. No algorithms, ads, or clickbait in sight.' /></p>
    <a href={sso_redirect} data-method='post' className='button button--block button-tertiary'><FormattedMessage id='sign_in_banner.sso_redirect' defaultMessage='Login or Register' /></a>
    </div>
  );
  }

  if (registrationsOpen) {
  signupButton = (
    <a href={signupUrl} className='button button--block'>
    <FormattedMessage id='sign_in_banner.create_account' defaultMessage='Create account' />
    </a>
  );
  } else {
  signupButton = (
    <button className='button button--block' onClick={openClosedRegistrationsModal}>
    <FormattedMessage id='sign_in_banner.create_account' defaultMessage='Create account' />
    </button>
  );
  }

  return (
  <div className='sign-in-banner'>
    <p><b>Sakurajima</b> is your gateway to the Japanese media (Anime/Manga/Visual Novels/Video Games/etc) fandom and creator community on the Fediverse. You can connect with other fans and creators on the Fediverse. You can learn more about our services and more on <a href='https://joinsakurajima.org'>our official website</a>.</p>
    {signupButton}
    <a href='/auth/sign_in' className='button button--block button-tertiary'><FormattedMessage id='sign_in_banner.sign_in' defaultMessage='Login' /></a>
    <p>If you signed up for an account have not received a verification email, check your SPAM folder. If you do not get it in an hour, send an email on the about page to the owner to have your account manually approved.</p>
  </div>
  );
};

export default SignInBanner;
