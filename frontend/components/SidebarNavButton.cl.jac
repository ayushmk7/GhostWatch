def:pub SidebarNavButton(
    item: dict[str, str], activeSection: str, onPick: object
) -> JsxElement {
    buttonClass = (
        "gw-sidebar-item is-active"
            if activeSection == item["label"]
            else "gw-sidebar-item"
    );

    def handleClick() -> None {
        onPick(item["label"]);
    }

    return
        <button
            type="button"
            className={buttonClass}
            onClick={handleClick}
        >
            <span className="gw-sidebar-icon">
                {item["icon"]}
            </span>
            <span className="gw-sidebar-copy">
                <strong>
                    {item["label"]}
                </strong>
                <span>
                    {item["meta"]}
                </span>
            </span>
        </button>;
}
