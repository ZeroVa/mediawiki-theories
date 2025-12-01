<?php

// Ensure Vector 2022 is available and default.
wfLoadSkin( 'Vector' );
$wgDefaultSkin = 'vector-2022';
$wgVectorDefaultSkinVersion = '2';
$wgVectorResponsive = true;

// Register the custom theme as a ResourceLoader module.
$wgResourceModules['ext.consciousnessTheme'] = [
    'styles' => [ 'consciousness-theme.css' ],
    'scripts' => [ 'consciousness-theme.js' ],
    'localBasePath' => __DIR__ . '/../theme',
    'remoteBasePath' => '/consciousness-theme',
    'position' => 'top',
    'targets' => [ 'desktop', 'mobile' ],
    'dependencies' => [ 'mediawiki.util' ],
];

// Load the module on every page.
$wgHooks['BeforePageDisplay'][] = static function ( \OutputPage $out ): bool {
    $out->addModules( 'ext.consciousnessTheme' );
    return true;
};
