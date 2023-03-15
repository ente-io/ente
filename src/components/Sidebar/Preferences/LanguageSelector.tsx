import { OptionWithDivider } from 'components/Collections/CollectionShare/publicShare/manage/selectComponents/OptionWithDivider';
import { LanguageLocale } from 'constants/locale';
import { useLocalState } from 'hooks/useLocalState';
import i18n from 'i18n';
import Select from 'react-select';
import { DropdownStyle } from 'styles/dropdown';
import { LS_KEYS } from 'utils/storage/localStorage';

const getLocaleDisplayName = (l: LanguageLocale) => {
    switch (l) {
        case LanguageLocale.en:
            return 'English';
        case LanguageLocale.fr:
            return 'Français';
    }
};

const getLanguageOptions = () => {
    return Object.values(LanguageLocale).map((lang) => ({
        label: getLocaleDisplayName(lang),
        value: lang,
    }));
};

export const LanguageSelector = () => {
    const [userLocale, setUserLocale] = useLocalState(
        LS_KEYS.LOCALE,
        i18n.language as LanguageLocale
    );
    const updateCurrentLocale = (newLocale: LanguageLocale) => {
        setUserLocale(newLocale);
        i18n.changeLanguage(newLocale);
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
