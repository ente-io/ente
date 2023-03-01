import { OptionWithDivider } from 'components/Collections/CollectionShare/publicShare/manage/selectComponents/OptionWithDivider';
import { locale } from 'constants/locale';
import { AppContext } from 'pages/_app';
import { useContext } from 'react';
import Select from 'react-select';
import { DropdownStyle } from 'styles/dropdown';

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
    const appContext = useContext(AppContext);
    const updateCurrentLocale = (newLocale: locale) => {
        appContext.setUserLocale(newLocale);
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
                label: getLocaleDisplayName(appContext.userLocale),
                value: appContext.userLocale,
            }}
            onChange={(e) => updateCurrentLocale(e.value)}
            styles={DropdownStyle}
        />
    );
};
