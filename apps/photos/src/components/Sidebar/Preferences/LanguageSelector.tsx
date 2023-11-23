import DropdownInput, { DropdownOption } from 'components/DropdownInput';
import { Language } from '@ente/shared/i18n/locale';
import { useLocalState } from '@ente/shared/hooks/useLocalState';
import { t } from 'i18next';
import { useRouter } from 'next/router';
import { getBestPossibleUserLocale } from '@ente/shared/i18n/utils';
import { LS_KEYS } from '@ente/shared/storage/localStorage';

const getLocaleDisplayName = (l: Language) => {
    switch (l) {
        case Language.en:
            return 'English';
        case Language.fr:
            return 'Français';
        case Language.zh:
            return '中文';
        case Language.nl:
            return 'Nederlands';
        case Language.es:
            return 'Español';
    }
};

const getLanguageOptions = (): DropdownOption<Language>[] => {
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

    const router = useRouter();

    const updateCurrentLocale = (newLocale: Language) => {
        setUserLocale(newLocale);
        router.reload();
    };

    return (
        <DropdownInput
            options={getLanguageOptions()}
            label={t('LANGUAGE')}
            labelProps={{ color: 'text.muted' }}
            selected={userLocale}
            setSelected={updateCurrentLocale}
        />
    );
};
