def:pub GhostShieldGraphic() -> JsxElement {
    return
        <svg
            className="gw-ghost-emblem gw-fade-up gw-stagger-2"
            viewBox="0 0 560 560"
            fill="none"
            aria-hidden="true"
        >
            <defs>
                <linearGradient id="gwRing" x1="98" y1="74" x2="442" y2="486">
                    <stop stopColor="rgba(220,239,255,0.85)"></stop>
                    <stop offset="0.55" stopColor="rgba(125,211,255,0.3)"></stop>
                    <stop offset="1" stopColor="rgba(82,229,213,0.5)"></stop>
                </linearGradient>
                <linearGradient id="gwShield" x1="280" y1="114" x2="280" y2="420">
                    <stop stopColor="rgba(255,255,255,0.22)"></stop>
                    <stop offset="0.4" stopColor="rgba(125,211,255,0.16)"></stop>
                    <stop offset="1" stopColor="rgba(17,22,29,0.02)"></stop>
                </linearGradient>
                <filter
                    id="gwGhostBlur"
                    x="-40%"
                    y="-40%"
                    width="180%"
                    height="180%"
                >
                    <feGaussianBlur stdDeviation="18"></feGaussianBlur>
                </filter>
            </defs>
            <circle
                cx="280"
                cy="280"
                r="196"
                stroke="url(#gwRing)"
                strokeWidth="1.4"
                opacity="0.8"
            ></circle>
            <circle
                cx="280"
                cy="280"
                r="156"
                stroke="rgba(220,239,255,0.18)"
                strokeWidth="1.2"
                strokeDasharray="8 14"
                opacity="0.8"
            ></circle>
            <circle
                cx="280"
                cy="280"
                r="110"
                stroke="rgba(82,229,213,0.18)"
                strokeWidth="1.1"
                opacity="0.9"
            ></circle>
            <circle
                cx="280"
                cy="280"
                r="150"
                fill="rgba(125,211,255,0.16)"
                filter="url(#gwGhostBlur)"
                opacity="0.22"
            ></circle>
            <path
                d="M280 116C221 142 185 150 156 150V276C156 358 209 424 280 452C351 424 404 358 404 276V150C375 150 339 142 280 116Z"
                fill="url(#gwShield)"
                stroke="rgba(220,239,255,0.4)"
                strokeWidth="1.5"
            ></path>
            <path
                d="M222 204C222 168 246 148 280 148C314 148 338 168 338 204V287C338 329 308 356 280 372C252 356 222 329 222 287V204Z"
                fill="rgba(9,12,16,0.52)"
                stroke="rgba(220,239,255,0.18)"
                strokeWidth="1.2"
            ></path>
            <circle cx="251" cy="228" r="12" fill="rgba(220,239,255,0.72)"></circle>
            <circle cx="309" cy="228" r="12" fill="rgba(220,239,255,0.72)"></circle>
            <path
                d="M240 282C255 300 265 308 280 308C295 308 305 300 320 282"
                stroke="rgba(125,211,255,0.7)"
                strokeWidth="8"
                strokeLinecap="round"
            ></path>
            <path
                d="M188 164C214 190 234 204 260 212"
                stroke="rgba(125,211,255,0.34)"
                strokeWidth="1.2"
                strokeDasharray="6 10"
            ></path>
            <path
                d="M372 164C346 190 326 204 300 212"
                stroke="rgba(82,229,213,0.34)"
                strokeWidth="1.2"
                strokeDasharray="6 10"
            ></path>
            <path
                d="M160 366C218 334 248 322 280 322C312 322 342 334 400 366"
                stroke="rgba(220,239,255,0.12)"
                strokeWidth="1.2"
            ></path>
        </svg>;
}
