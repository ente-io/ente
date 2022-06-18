import { styled } from '@mui/material';

// const OldPlanTile = styled('div')<{ currentlySubscribed: boolean }>`
//     border-radius: 20px;
//     width: 220px;
//     border: 2px solid #333;
//     padding: 30px;
//     margin: 10px;
//     text-align: center;
//     font-size: 20px;
//     background-color: #ffffff00;
//     display: flex;
//     justify-content: center;
//     align-items: center;
//     flex-direction: column;
//     cursor: ${(props) =>
//         props.currentlySubscribed ? 'not-allowed' : 'pointer'};
//     border-color: ${(props) => props.currentlySubscribed && '#56e066'};
//     transition: all 0.3s ease-out;
//     overflow: hidden;
//     position: relative;

//     & > div:first-child::before {
//         content: ' ';
//         height: 600px;
//         width: 50px;
//         background-color: #444;
//         left: 0;
//         top: -50%;
//         position: absolute;
//         transform: rotate(45deg) translateX(-200px);
//         transition: all 0.5s ease-out;
//     }

//     &:hover
//         ${(props) =>
//             !props.currentlySubscribed &&
//             css`
//                  {
//                     transform: scale(1.1);
//                     background-color: #ffffff11;
//                 }
//             `}
//         &:hover
//         > div:first-child::before {
//         transform: rotate(45deg) translateX(300px);
//     }
// `;

const PlanTile = styled('div')<{ current: boolean }>(({ theme, current }) => ({
    padding: theme.spacing(3),
    border: `1px solid ${theme.palette.divider}`,

    '&:hover': {
        backgroundColor: ' rgba(40, 214, 101, 0.11)',
        cursor: 'pointer',
    },
    ...(current && {
        borderColor: theme.palette.accent.main,
        cursor: 'not-allowed',
        '&:hover': { backgroundColor: 'transparent' },
    }),
    width: ' 260px',
    borderRadius: '8px 8px 0 0',
    '&:not(:first-of-type)': {
        borderTopLeftRadius: '0',
    },

    '&:not(:last-of-type)': {
        borderTopRightRadius: '0',
    },
}));

export default PlanTile;
