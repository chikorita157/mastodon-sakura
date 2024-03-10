import {useState} from "react";
import axios from "axios";

const typeToText = (type:"anilist"|"myanimelist") => {
  switch (type) {
    case "anilist": return "AniList";
    case "myanimelist": return "MyAnimeList";
    default: return "";
  }
}

const randomString = (dictionary:string, length:number) => {
  let r = "";
  for (let i=0;i<length;i++) {
    r += dictionary[Math.floor(Math.random() * dictionary.length)];
  }
  return r;
}

export default function ExternalVerificationButton ({type, client_id, base_url}:{type:"anilist"|"myanimelist", client_id:string, base_url:string}) {

  return (
    <button
      style={{display: "flex", placeItems: "center", gap: "10px", width:"140px", fontWeight:"700", marginTop:"8px"}}
      onClick={() => {
        switch (type) {
          case "anilist": {
            let urlAniList = new URL('https://anilist.co/api/v2/oauth/authorize');
            for (const [key, value] of Object.entries({
              client_id,
              response_type: "code",
              redirect_uri: `${base_url}/external_verification/anilist`
            })) {
              urlAniList.searchParams.append(key, value as string);
            }

            let urlFirst = new URL(`${base_url}/external_verification/first`);
            for (const [key, value] of Object.entries({
              type,
              next: btoa(urlAniList.toString())
            })) {
              urlFirst.searchParams.append(key, value as string);
            }
            //console.log(urlAniList);
            location.href = urlFirst.toString();
            break;
          }
          case "myanimelist": {
            const challengeMal = randomString("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~", 45);
            let urlMal = new URL('https://myanimelist.net/v1/oauth2/authorize');
            for (const [key, value] of Object.entries({
              response_type: "code",
              client_id,
              code_challenge: challengeMal,
              state: challengeMal,
              redirect_uri: `${base_url}/external_verification/myanimelist`
            })) {
              urlMal.searchParams.append(key, value as string);
            }

            let urlFirst = new URL(`${base_url}/external_verification/first`);
            for (const [key, value] of Object.entries({
              type,
              challenge: challengeMal,
              next: btoa(urlMal.toString())
            })) {
              urlFirst.searchParams.append(key, value as string);
            }
            //console.log(urlMal);
            location.href = urlFirst.toString();
            break;
          }
        }
      }}>

      {
        type === "anilist" &&
        <svg
          viewBox="0 0 172 172"
          width="30px" height="30px"
          xmlns="http://www.w3.org/2000/svg"
          style={{backgroundColor: "#19212d", borderRadius: "0.375rem"}}>
          <g fillRule="evenodd">
            <path
              d="M104.7,104.5V52.9c0-3-1.6-4.6-4.6-4.6H90c-3,0-4.6,1.6-4.6,4.6c0,0,0,11.3,0,24.5c0,0.7,6.6,3.9,6.8,4.6c5.1,19.8,1.1,35.6-3.7,36.4c7.8,0.4,8.7,4.2,2.9,1.6c0.9-10.6,4.4-10.5,14.4-0.4c0.1,0.1,2.1,4.2,2.2,4.2c11.3,0,23.7,0,23.7,0c3,0,4.6-1.6,4.6-4.6v-10.1c0-3-1.6-4.6-4.6-4.6H104.7z"
              fill="#02a9ff"/>
            <path
              d="M62.8,48.4l-26.5,75.4h20.6l4.5-13h22.4l4.4,13h20.5L82.3,48.4H62.8z M66.1,94l6.4-20.9l7,20.9H66.1z"
              fill="#fefefe"/>
          </g>
        </svg>
      }
      {
        type === "myanimelist" &&
        <svg
          viewBox="0 0 24 24"
          width="30px" height="30px"
          xmlns="http://www.w3.org/2000/svg"
          style={{backgroundColor: "#2e51a2", borderRadius: "0.375rem"}}>
          <path
            d="m8.7 8.2v6.8h-1.7v-4.2l-1.6 1.9-1.6-2v4.2h-1.7v-6.8h1.8l1.5 2 1.6-2c0 .1 1.7.1 1.7.1zm6.9 1.7v5.1h-1.9v-2.3h-2.2c.1.4.2 1 .3 1.4.1.3.2.6.5.9l-1.4.9c-.3-.5-.5-1.1-.7-1.7s-.3-1.2-.4-1.7c-.1-.6-.1-1.2.1-1.8s.5-1.1.9-1.5c.3-.2.6-.4.9-.6s.6-.2.9-.3.6-.1 1-.1c.3 0 .9-.1 1.9 0l.4 1.4h-2.2c-.5 0-.7 0-1.1.2-.6.3-1 .9-1 1.5h2.1v-1.5zm3.2-1.7v5.3h2.5l-.3 1.4h-3.9v-6.8z"
            fill="white"/>
        </svg>
      }

      <div>{typeToText(type)}</div>
    </button>
  )
}
