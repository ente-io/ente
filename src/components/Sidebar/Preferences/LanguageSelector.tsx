import { OptionWithDivider } from 'components/Collections/CollectionShare/publicShare/manage/selectComponents/OptionWithDivider';
import { locale } from 'constants/locale';
import { useLocalState } from 'hooks/useLocalState';
import { useRouter } from 'next/router';
import Select from 'react-select';
import { DropdownStyle } from 'styles/dropdown';
import { LS_KEYS } from 'utils/storage/localStorage';
import { getBestPossibleUserLocale } from 'utils/strings';

const getLocaleDisplayName = (l: locale) => {
    switch (l) {
        case locale.en:
            return 'English';
        case locale.fr:
            return 'Français';
    }
};

const getLanguageOptions = () => {
    return Object.values(locale).map((lang) => ({
        label: getLocaleDisplayName(lang),
        value: lang,
    }));
};

export const LanguageSelector = () => {
    const [userLocale, setUserLocale] = useLocalState(
        LS_KEYS.LOCALE,
        getBestPossibleUserLocale()
    );
    const router = useRouter();
    const updateCurrentLocale = (newLocale: locale) => {
        setUserLocale(newLocale);
        router.reload();
    };

    return (
        <Select
            menuPosition="fixed"
            options={getLanguageOptions()}
            components={{
                Option: OptionWithDivider,
            }}
            isSearchable={false}
            value={{
                label: getLocaleDisplayName(userLocale),
                value: userLocale,
            }}
            onChange={(e) => updateCurrentLocale(e.value)}
            styles={DropdownStyle}
        />
    );
};
