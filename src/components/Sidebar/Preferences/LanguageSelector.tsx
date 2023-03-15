import { OptionWithDivider } from 'components/Collections/CollectionShare/publicShare/manage/selectComponents/OptionWithDivider';
import { Language } from 'constants/locale';
import { useLocalState } from 'hooks/useLocalState';
import i18n from 'i18n';
import { useEffect } from 'react';
import Select from 'react-select';
import { DropdownStyle } from 'styles/dropdown';
import { getBestPossibleUserLocale } from 'utils/i18n';
import { LS_KEYS } from 'utils/storage/localStorage';

const getLocaleDisplayName = (l: Language) => {
    switch (l) {
        case Language.en:
            return 'English';
        case Language.fr:
            return 'Français';
    }
};

const getLanguageOptions = () => {
    return Object.values(Language).map((lang) => ({
        label: getLocaleDisplayName(lang),
        value: lang,
    }));
};

export const LanguageSelector = () => {
    const [userLocale, setUserLocale] = useLocalState(
        LS_KEYS.LOCALE,
        getBestPossibleUserLocale()
    );

    useEffect(() => {
        i18n.changeLanguage(userLocale);
    }, [userLocale]);

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
            onChange={(e) => setUserLocale(e.value)}
            styles={DropdownStyle}
        />
    );
};
