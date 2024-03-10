import ExternalVerificationButton from "flavours/glitch/components/admin/ExternalVerificationButton";

const message = "Alternatively, you may use an existing account (> 90 days old) with the following services to approve your account instantly";

export default function ExternalVerification({anilist_id, mal_id, base_url}:{anilist_id?:string, mal_id?:string, base_url:string}) {
  return (
    <div style={{borderWidth: "1px", padding: "0.5rem"}}>
      <div style={{fontWeight:"400", fontSize:"0.8rem"}}>{ message }</div>
      { anilist_id && <ExternalVerificationButton type="anilist" client_id={anilist_id} base_url={base_url}/> }
      { mal_id && <ExternalVerificationButton type="myanimelist" client_id={mal_id} base_url={base_url}/> }
    </div>
  )
}
