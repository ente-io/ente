export function BackgroundOverlay() {
    return (
        <img
            style={{ aspectRatio: "2/1" }}
            width="100%"
            src="/images/subscription-card-background/1x.png"
            srcSet="/images/subscription-card-background/2x.png 2x,
                        /images/subscription-card-background/3x.png 3x"
        />
    );
}
