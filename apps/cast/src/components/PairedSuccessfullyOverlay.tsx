import FilledCircleCheck from './FilledCircleCheck';

export default function PairedSuccessfullyOverlay() {
    return (
        <div
            style={{
                position: 'fixed',
                top: 0,
                right: 0,
                height: '100%',
                width: '100%',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                zIndex: 100,
                backgroundColor: 'black',
            }}>
            <div
                style={{
                    display: 'flex',
                    alignItems: 'center',
                    flexDirection: 'column',
                    textAlign: 'center',
                }}>
                <FilledCircleCheck />
                <h2
                    style={{
                        marginBottom: 0,
                    }}>
                    Pairing Complete
                </h2>
                <p
                    style={{
                        lineHeight: '1.5rem',
                    }}>
                    We're preparing your album.
                    <br /> This should only take a few seconds.
                </p>
            </div>
        </div>
    );
}
