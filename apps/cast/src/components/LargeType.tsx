const colourPool = [
    '#87CEFA', // Light Blue
    '#90EE90', // Light Green
    '#F08080', // Light Coral
    '#FFFFE0', // Light Yellow
    '#FFB6C1', // Light Pink
    '#E0FFFF', // Light Cyan
    '#FAFAD2', // Light Goldenrod
    '#87CEFA', // Light Sky Blue
    '#D3D3D3', // Light Gray
    '#B0C4DE', // Light Steel Blue
    '#FFA07A', // Light Salmon
    '#20B2AA', // Light Sea Green
    '#778899', // Light Slate Gray
    '#AFEEEE', // Light Turquoise
    '#7A58C1', // Light Violet
    '#FFA500', // Light Orange
    '#A0522D', // Light Brown
    '#9370DB', // Light Purple
    '#008080', // Light Teal
    '#808000', // Light Olive
];

export default function LargeType({ chars }: { chars: string[] }) {
    return (
        <table
            style={{
                fontSize: '4rem',
                fontWeight: 'bold',
                fontFamily: 'monospace',
                display: 'flex',
                position: 'relative',
            }}>
            {chars.map((char, i) => (
                <tr
                    key={i}
                    style={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        padding: '0.5rem',
                        // alternating background
                        backgroundColor: i % 2 === 0 ? '#2e2e2e' : '#5e5e5e',
                    }}>
                    <span
                        style={{
                            color: colourPool[i % colourPool.length],
                            lineHeight: 1.2,
                        }}>
                        {char}
                    </span>
                    <span
                        style={{
                            fontSize: '1rem',
                        }}>
                        {i + 1}
                    </span>
                </tr>
            ))}
        </table>
    );
}
