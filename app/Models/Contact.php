<?php

namespace App\Models;

use App\Services\ContactImportService;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Contact extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'birthdate',
    ];

    protected $casts = [
        'birthdate' => 'date',
    ];

    /**
     * Get the gravatar URL for the contact.
     */
    public function getGravatarUrlAttribute(): string
    {
        $hash = md5(strtolower(trim($this->email)));
        return "https://www.gravatar.com/avatar/{$hash}?d=identicon&s=80";
    }

    /**
     * Get formatted phone number.
     */
    public function getFormattedPhoneAttribute(): ?string
    {
        if (!$this->phone) {
            return null;
        }

        try {
            return phone($this->phone, 'US')->formatE164();
        } catch (\Exception $e) {
            return $this->phone;
        }
    }

    /**
     * Set phone attribute with US formatting.
     */
    public function setPhoneAttribute($value): void
    {
        if (empty($value)) {
            $this->attributes['phone'] = null;
            return;
        }

        try {
            $this->attributes['phone'] = phone($value, 'US')->formatE164();
        } catch (\Exception $e) {
            $this->attributes['phone'] = $value;
        }
    }

    /**
     * Get paginated contacts with gravatar URLs.
     */
    public static function getPaginatedWithGravatar(int $perPage = 15)
    {
        $contacts = static::orderBy('created_at', 'desc')
            ->paginate($perPage);

        // Add gravatar URL to each contact
        $contacts->getCollection()->transform(function ($contact) {
            $contact->gravatar_url = $contact->gravatar_url;
            return $contact;
        });

        return $contacts;
    }

    /**
     * Import contacts from CSV file using the import service.
     */
    public static function importFromCsv(string $filePath): array
    {
        $importService = new ContactImportService();
        return $importService->importFromCsv($filePath);
    }

    /**
     * Check if email already exists.
     */
    public static function emailExists(string $email): bool
    {
        return static::where('email', strtolower(trim($email)))->exists();
    }

    /**
     * Get all existing emails for duplicate checking.
     */
    public static function getExistingEmails(): array
    {
        return static::pluck('email')->toArray();
    }

    /**
     * Create contact with normalized email.
     */
    public static function createContact(array $data): self
    {
        if (isset($data['email'])) {
            $data['email'] = strtolower(trim($data['email']));
        }
        
        return static::create($data);
    }

    /**
     * Scope for searching contacts by name or email.
     */
    public function scopeSearch($query, string $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('name', 'like', "%{$search}%")
              ->orWhere('email', 'like', "%{$search}%");
        });
    }

    /**
     * Scope for filtering by date range.
     */
    public function scopeCreatedBetween($query, string $startDate, string $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }
}
