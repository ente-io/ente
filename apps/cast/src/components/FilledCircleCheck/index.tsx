import { useEffect, useState } from 'react';
import styles from './FilledCircleCheck.module.scss'; // Import our CSS module

const FilledCircleCheck = () => {
    const [animate, setAnimate] = useState(false);

    useEffect(() => {
        setAnimate(true);
    }, []);

    return (
        <div className={`${styles.circle} ${animate ? styles.animate : ''}`}>
            <svg
                className={styles.checkmark}
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 52 52">
                <circle
                    className={styles.checkmark__circle}
                    cx="26"
                    cy="26"
                    r="25"
                    fill="green"
                />
                <path
                    className={styles.checkmark__check}
                    fill="none"
                    d="M14.1 27.2l7.1 7.2 16.7-16.8"
                />
            </svg>
        </div>
    );
};

export default FilledCircleCheck;
